# Lab 11 Submission — Reproducible Builds with Nix

## Task 1 — Reproducible Go build via flake (4 pts)

### `flake.nix`

Pinned to `nixpkgs/nixos-25.05` (not `24.11`) because QuickNotes `go.mod` requires Go ≥ 1.24 and `24.11` only ships Go 1.23. Lockfile: [`flake.lock`](../flake.lock).

Uses `buildGoModule` (stdlib-only module → `vendorHash = null`), `env.CGO_ENABLED = "0"`, `ldflags = [ "-s" "-w" ]`, packages `quicknotes` / `default`, and a `devShell` with `go` / `gopls` / `golangci-lint`.

Full file: [`flake.nix`](../flake.nix).

### Build log excerpt (`nix build .#quicknotes`)

```text
building '/nix/store/...-quicknotes-0.1.0.drv'...
quicknotes> Building subPackage .
quicknotes> ok          quicknotes      0.014s
quicknotes> ...
```

Binary: `/nix/store/...-quicknotes-0.1.0/bin/quicknotes` (~5.6 MB static).

### Two independent store hashes (must match)

| Env | How | `nix-store --query --hash $(readlink result)` |
|-----|-----|-----------------------------------------------|
| **A** | `docker run nixos/nix:2.24.12` container `#1` | `sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s` |
| **B** | fresh `nixos/nix:2.24.12` container `#2` (separate `/nix`) | `sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s` |

Hashes are **identical**.

### Runtime proof

```text
$ ./result/bin/quicknotes &
$ curl -s http://127.0.0.1:8080/health
{"notes":0,"status":"ok"}
```

### Design questions (a–d)

**a) Why isn't `go build` bit-identical across machines?**  
Toolchains embed build IDs / paths, timestamps can leak into archives/metadata, and module resolution can float without a lock. Two laptops with "Go 1.24" can still differ in patch level, `GOROOT`, and cgo linkage. Nix pins the exact Go derivation + src hash, so the store path (and contents) match.

**b) What is `vendorHash`? What if `null`?**  
`vendorHash` is the fixed-output hash of the Go module download / vendor tree Nix fetches before compiling. If wrong, the build fails with the expected `got:` hash. `vendorHash = null` skips that fixed-output derivation and allows a non-vendored fetch — required here because the module has **no third-party deps** (`go: no dependencies to vendor`; a non-null empty hash errors with "vendor folder is empty" on nixos-25.05).

**c) Why is `flake.lock` critical?**  
It pins nixpkgs (and every flake input) to a precise Git revision + NAR hash. Delete it before a second build and evaluation may resolve a newer `nixos-25.05` tip → different Go/compiler → different outputs. Commit of `flake.lock` is the reproducibility contract.

**d) `buildGoModule` vs `buildGoApplication`?**  
`buildGoModule` is in nixpkgs proper and vendoring/`vendorHash`-based. `buildGoApplication` (gomod2nix) generates Nix from `go.mod` for richer graph control. For a tiny stdlib-only QuickNotes binary, `buildGoModule` is enough and simpler — one file, no generators.

---

## Task 2 — Deterministic OCI image (4 pts)

### Flake package `docker`

`pkgs.dockerTools.buildImage` wraps the Task 1 binary:

- `Entrypoint = [ "/bin/quicknotes" ]`
- `ExposedPorts."8080/tcp"`
- `User = "65532:65532"` (Lab 6 nonroot UID) + minimal `/etc/passwd`/`group`
- Built **without Docker** — only Nix

### Load + health

```text
$ docker load < result
$ docker run --rm -p 18080:8080 quicknotes:lab11
$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}

User=65532:65532 Entrypoint=["/bin/quicknotes"] Exposed={"8080/tcp":{}}
```

### Two independent image digests (must match)

```text
# Env A (container #1)
6c796a77aeceec80f72d3a5b4a3b566306b7739c2f698d30af75e3403d90ed25  result-docker

# Env B (fresh container #2)
6c796a77aeceec80f72d3a5b4a3b566306b7739c2f698d30af75e3403d90ed25  result-docker-B
```

Identical SHA-256 of the OCI tarball.

### Image size: Nix vs Lab 6 Docker

| Image | Size (docker images) | Notes |
|-------|----------------------|-------|
| `quicknotes:lab11` (Nix `dockerTools`) | **23.1 MB** | tarball on disk ~3.3 MB gzip |
| `qn-lab6:run1` / `run2` (Dockerfile) | **22.5 MB** | distroless + static binary |

Sizes are in the same ballpark; the Nix image carries ca-certs + fake passwd. The win is **digest stability**, not size.

### Lab 6 `--no-cache` digests differ

```text
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6

qn-lab6:run1 sha256:16978dd27b75f7126240e7bacbc3909d1f59d494016279369b2afa6b7c534146 22.5MB
qn-lab6:run2 sha256:8b48c237c5981bf9d04a097e1b4e4bb92e6f07643c23874e5e173f42a13aa98d 22.5MB
```

Same Dockerfile, same tree — **different** image IDs (timestamps / non-reproducible layers).

### Design questions (e–g)

**e) What makes `docker build` non-deterministic?**  
Layer metadata timestamps, base image tags that move (`alpine`/`golang` digests change), `apt`/`apk` indexes resolving "today's" packages, build-cache opacity, and Go/buildkit IDs. Even `--no-cache` from one Git SHA usually yields a new image ID each run (as shown above).

**f) What can a security auditor prove with a reproducible image that a signed-but-non-reproducible one cannot?**  
Signature proves *who* published a blob. Reproducibility proves *what* was built matches *public source* independently. A malicious CI can sign a backdoored blob; independent rebuilds failing to match the signed digest expose the lie (xz-utils lesson).

**g) Trade-off — why is `docker build` still default?**  
Nix has a steep learning curve, slower cold builds without a binary cache, and awkward packaging for some ecosystems. Dockerfiles are familiar, Hub-cached, and "good enough" for most teams that prioritize ship-speed over bit-identity.

---

## Bonus — CI-verified reproducibility (2 pts)

### Workflow

[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml):

- Triggers on push + pull_request
- Parallel jobs `build-a` / `build-b` on fresh `ubuntu-24.04` runners
- Determinate Nix installer pinned by SHA (`ef8a1480…` = v22)
- Each job: `nix build .#docker` → `sha256sum result`
- Job `compare` fails if digests differ

Deliberate break (B.3): repository variable `NIX_REPRO_BREAK=true` makes job A rewrite `tag = "lab11-break"` (and set `SOURCE_DATE_EPOCH=0`). Pure Nix ignores ambient `SOURCE_DATE_EPOCH` alone, so the tag rewrite is what forces a visible mismatch.

### CI evidence

*(filled after push — green run URL + red run with BREAK=true)*

### Design questions (h–j)

**h) Laptop vs CI proof**  
Laptop proof can share a warm store, same LAN mirrors, and accidental impurities you never notice. CI on two fresh runners is what an auditor can cite: independent evaluation without your laptop's `/nix/store` residue.

**i) Why two parallel jobs, not one job twice?**  
A single job reuses the same runner filesystem, Nix daemon, and cache. Shared state can hide machine-specific leaks (locale, leftover `/tmp`, cached impure inputs). Two parallel fresh VMs closer to "two independent machines."

**j) `SOURCE_DATE_EPOCH` and `dockerTools`**  
Timestamps normally leak into tarball members / image JSON. Nix sets a fixed epoch inside the sandbox; `dockerTools.buildImage` produces layers with deterministic mtimes. A host `SOURCE_DATE_EPOCH` does not rewrite a pure derivation — hence the explicit tag rewrite for the red CI demo.

---

## How to reproduce

```bash
# Requires Nix with flakes (or: docker run --rm -v "$PWD":/repo -w /repo nixos/nix:2.24.12)
nix build .#quicknotes
nix-store --query --hash "$(readlink result)"
./result/bin/quicknotes &
curl -s localhost:8080/health

nix build .#docker
sha256sum result
docker load < result
```
