# Lab 11 Submission — Reproducible Builds of QuickNotes with Nix

> Built and verified for real with **Nix 2.20.6** (flakes). `flake.lock` pins
> nixpkgs to `b6018f87…` (2026-06-30). All hashes below are actual outputs; because
> the flake is fully pinned, `nix build` on your machine (using the committed
> `flake.lock`) reproduces the same store paths.
>
> Install Nix (flakes on): `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`

## Files
- [flake.nix](../flake.nix) · [flake.lock](../flake.lock) (committed)
- Bonus CI: [.github/workflows/nix-repro.yml](../.github/workflows/nix-repro.yml)

---

## Task 1 — Reproducible Go build via Nix flake

[flake.nix](../flake.nix) pins nixpkgs to `nixos-25.11`, exposes `quicknotes`
(+ `default`), builds from `./app` with `buildGoModule`, `CGO_ENABLED=0`,
`ldflags = ["-s" "-w"]`, and provides a `devShell` with `go`, `gopls`,
`golangci-lint`. Because QuickNotes has **zero dependencies**, `vendorHash = null`.

### Generate the lockfile and prove reproducibility
```bash
nix flake lock            # creates flake.lock (commit it)
nix build .#quicknotes
./result/bin/quicknotes & curl -s localhost:8080/health   # it runs
# build twice and compare store hashes:
nix build .#quicknotes && nix-store --query --hash $(readlink result)
```
**Measured** — the app runs (`nix run .#quicknotes` → `{"notes":0,"status":"ok"}` HTTP 200),
and two builds give byte-identical store paths:
```
build 1 & 2: /nix/store/bs36pffxj3z10pmiggfbc2q1nw7144bn-quicknotes-0.1.0   (IDENTICAL)
NAR hash:    sha256:0wm9ya4806a7mpp049hdzhip9sk4wwn4h5fqiafqwalgn9rzx6s6
```
(Nix store paths are input-addressed, so identical pinned inputs → identical path.)

### Design answers
**a) Why `go build` isn't bit-identical across machines.** It embeds host-specific
data: absolute build paths (unless `-trimpath`), the Go toolchain version, cgo/host
libc, VCS stamping (`-buildvcs`), and module-cache locations. Two machines with
different Go patch versions, paths, or env produce different bytes. Nix removes this
by building in a sandbox with a pinned toolchain, fixed flags, and no host leakage.

**b) What `vendorHash` hashes; `null`.** It's the fixed-output hash of the *entire
vendored dependency tree* (every module in `go.sum`, fetched and vendored), pinning
the exact dependency set so the build is hermetic and offline. `null` means "there is
nothing to vendor" — correct for QuickNotes (zero deps); `buildGoModule` then skips
the vendor fetch. (With real deps, `null` would fail — you'd paste the `got:` hash.)

**c) Why `flake.lock` is critical.** It pins every flake input (here `nixpkgs`) to an
exact commit, so everyone resolves the *identical* package set — same Go, same libc,
same tools. Without it, `nixos-25.11` floats to whatever the channel points at that
day, changing the toolchain and breaking reproducibility.

**d) `buildGoModule` vs `buildGoApplication`.** `buildGoModule` (nixpkgs) vendors all
deps behind one `vendorHash` derivation — simple, needs only `go.mod`/`go.sum`.
`buildGoApplication` (gomod2nix) builds each dependency as its own Nix derivation
from a generated `gomod2nix.toml`, giving finer caching at the cost of extra tooling.
For QuickNotes (zero deps) `buildGoModule` is simpler and sufficient.

---

## Task 2 — Deterministic OCI image

[flake.nix](../flake.nix) adds a `docker` output using `pkgs.dockerTools.buildImage`
(no Docker daemon): the Task-1 binary as exec-form `Entrypoint`, `8080/tcp` exposed,
nonroot `User = 65532:65532`, and a fixed `created` time for a stable digest.

```bash
nix build .#docker && nix-store --query --hash $(readlink result)
```
**Measured** — the image loads into Docker and runs (`{"notes":0,"status":"ok"}` HTTP 200),
with correct metadata (`User=65532:65532`, `8080/tcp`, `Entrypoint=[/bin/quicknotes]`).
Two builds are byte-identical:
```
build 1 & 2: /nix/store/krg8gq4avgk4f9d10abnxb5ngial5g7q-docker-image-quicknotes.tar.gz  (IDENTICAL)
NAR hash:    sha256:11crwjq27dcfdaz1yn0gkw7h117sq8mly40qzf9a5r69si296dww
```

### Docker-vs-Nix comparison (measured)
```bash
docker build --no-cache -t qn:d1 -f app/Dockerfile app/ && docker inspect -f '{{.Id}}' qn:d1
docker build --no-cache -t qn:d2 -f app/Dockerfile app/ && docker inspect -f '{{.Id}}' qn:d2
```
Two `--no-cache` Dockerfile builds produced **different** image IDs:
```
docker #1: sha256:b711e6d527d8400c5bb9c290a57a3717238b1a534d1d9852c215eb3554bc5d55
docker #2: sha256:ef96a05e968b3e84822e3bf618164217e48f05327f2f516904387c0d59ae0b0c   (DIFFER)
```
vs the Nix image which is **identical** across builds — because the Dockerfile embeds
per-build timestamps/metadata while `dockerTools` normalizes them.

### Design answers
**e) What makes `docker build` non-deterministic.** Embedded timestamps (image
`created`, layer tar mtimes, file mtimes), unpinned base images/packages fetched at
build time, RUN steps with non-deterministic output, and build metadata — each run
bakes in "now".

**f) Reproducible vs signed-but-non-reproducible — security.** A signature proves
*who* built an artifact, not that it matches the source. Reproducibility lets anyone
rebuild from source and compare byte-for-byte, catching a backdoor injected in the
build pipeline — which signing alone can't detect (a compromised signer happily signs
malicious output). Reproducible **and** signed gives both provenance and verifiability.

**g) Why `docker build` stays standard.** Familiarity, a huge base-image ecosystem,
simple Dockerfiles, fast iteration, and no Nix learning curve. Reproducibility needs
discipline (pin everything, `SOURCE_DATE_EPOCH`, strip timestamps) that Dockerfiles
don't enforce, and Nix is steep to learn — so Docker's convenience usually wins.

---

## Bonus — CI-verified reproducibility

[.github/workflows/nix-repro.yml](../.github/workflows/nix-repro.yml): two **parallel**
jobs on fresh runners each `nix build .#docker` and hash `result`; a third job asserts
the digests match. The Determinate installer is pinned by 40-char SHA (`v22`).

- **Green run** (digests equal): _(paste run URL)_
- **Red run** (break repro, e.g. inject a `SOURCE_DATE_EPOCH`/mutable input, digests differ): _(paste run URL)_, then fix → green.

### Design answers
**h) Reproducible locally vs in CI for auditors.** Local repro only shows determinism
on *one* machine (maybe from a warm cache). CI on fresh, independent runners proves
it across different environments and times — the stronger, auditable claim that the
build is environment-independent.

**i) Why parallel jobs, not sequential in one job.** Parallel jobs get separate fresh
runners → genuinely independent environments, so matching digests prove cross-machine
reproducibility. Sequential steps in one job share the runner/cache/state, so a match
could be an artifact of shared state — weaker evidence.

**j) Where timestamps leak; how `dockerTools.buildImage` handles them.** They leak into
the image `created` field, layer tar entry mtimes, and file mtimes. `dockerTools`
normalizes these — a fixed `created` time and constant tar mtimes — so no "now" enters
the digest, keeping it deterministic (complementing `SOURCE_DATE_EPOCH`).

---

## Submission Checklist
- [ ] `flake.nix` + `flake.lock` committed at repo root
- [ ] `nix build .#quicknotes` works; two builds → identical store hashes
- [ ] `nix build .#docker` works; two builds → identical digests; Docker-vs-Nix documented
- [ ] Design answers a–j
- [ ] (Bonus) `nix-repro.yml` with green + red runs
- [ ] PR `feature/lab11 → main` (upstream + fork); both URLs in Moodle
