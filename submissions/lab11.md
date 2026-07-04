# Lab 11 — Reproducible Builds with Nix

Fork: **tdzdslippen/DevOps-Intro**, branch `feature/lab11`.

Built with **Nix inside `nixos/nix:2.28.2` Docker** (no local Nix on macOS — same approach as lab doc suggests for a second environment).

Evidence: [`artifacts/lab11/`](../artifacts/lab11/).

Flake: [`flake.nix`](../flake.nix) + [`flake.lock`](../flake.lock) (nixpkgs pin `nixos-25.11` → `b6018f87…`).

---

## Task 1 — Reproducible Go build

### flake.nix (summary)

- **Input:** `nixpkgs` → `github:NixOS/nixpkgs/nixos-25.11` (Go **1.24** via `buildGo124Module`, matches `app/go.mod`)
- **Package `quicknotes` / `default`:** `buildGo124Module` on `./app`
  - `vendorHash = null` — stdlib-only module, empty vendor tree (Nix requires explicit `null`)
  - `CGO_ENABLED = 0`, `ldflags = [ "-s" "-w" ]`
  - `postInstall` copies `seed.json` to `$out/share/quicknotes/`
- **`devShell`:** `go_1_24`, `gopls`, `golangci-lint`

**Why `buildGo124Module` not `buildGoApplication`?** It's the nixpkgs helper for Go modules with the standard fetch-vendor → build flow; `buildGoApplication` is the newer flake-parts/callPackage style — fine for apps already packaged in nixpkgs, but `buildGoModule`/`buildGo124Module` is the straight path for our local `./app` source (see design **d**).

### Build log (excerpt)

```text
$ nix build .#quicknotes   # inside nixos/nix container
quicknotes> Building subPackage .
quicknotes> ok          quicknotes      0.006s
quicknotes> stripping ... /nix/store/...-quicknotes-0.1.0/bin
```

### Two-environment store hash (must match)

| Env | Hash |
|-----|------|
| Container A | `sha256:0wqq4v7dclvfr0n7q09gqw0rr4j11055bf8670pyim8r5yb4bgcm` |
| Container B | `sha256:0wqq4v7dclvfr0n7q09gqw0rr4j11055bf8670pyim8r5yb4bgcm` |

Files: [`quicknotes-hash-env-a.txt`](../artifacts/lab11/quicknotes-hash-env-a.txt), [`quicknotes-hash-env-b.txt`](../artifacts/lab11/quicknotes-hash-env-b.txt)

### Binary runs

```text
$ DATA_PATH=/tmp/notes.json SEED_PATH=app/seed.json ./result/bin/quicknotes &
$ curl -s http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
```

### Design a–d

**a) Why plain `go build` isn't bit-identical**

Build IDs, embedded timestamps, path prefixes in debug info (without `-trimpath`), different module cache contents, and toolchain patch levels all leak into the binary. Two laptops with “same Git SHA” still differ at the bit level.

**b) `vendorHash`**

SHA-256 over the **vendored/fetched module tree** Nix materializes before compile. Wrong hash → fixed-output derivation fails with `got: sha256-…`. `vendorHash = null` is the explicit opt-in for **zero third-party modules** (our case).

**c) `flake.lock`**

Locks **exact nixpkgs revision** (and flake inputs). Delete it → second machine may resolve a newer nixpkgs commit → different Go/toolchain → different store hash. Most important reproducibility file in a flake repo.

**d) `buildGoModule` vs `buildGoApplication`**

`buildGoModule` is the classic nixpkgs function for third-party or local modules with `vendorHash`. `buildGoApplication` (newer) targets flake-centric app packaging. QuickNotes is a small local module — `buildGo124Module` is the direct, documented fit.

---

## Task 2 — Deterministic OCI image

### flake output `docker`

`pkgs.dockerTools.buildImage` — no Docker daemon:

- `copyToRoot` with `/bin/quicknotes` + `/data/seed.json`
- `User = "65532:65532"`, `ExposedPorts."8080/tcp"`, exec `Entrypoint`
- `created = "1970-01-01T00:00:01Z"` + `SOURCE_DATE_EPOCH=0` in CI

Load: `nix build .#docker && docker load < result`

### Two-environment tarball SHA-256 (must match)

| Env | sha256sum |
|-----|-----------|
| A | `5804a89d1df139024d6d3335fbeabd21fa80ded1f38e5ebcd6d847d1b1e29fb5` |
| B | `5804a89d1df139024d6d3335fbeabd21fa80ded1f38e5ebcd6d847d1b1e29fb5` |

[`docker-tarball-sha256-env-*.txt`](../artifacts/lab11/)

### vs Lab 6 Docker (`docker build --no-cache` ×2)

| Tag | Image ID |
|-----|----------|
| run1 | `sha256:6dcae5ed0cee45a1b3a54bd8a5db8aed4b4a568fab83d592c816c7b7e94b912a` |
| run2 | `sha256:286c1a59e327a16a9ef41b66fcbb28542c122f150c1803a6de3203bd72189060` |

Different IDs — layer timestamps / build cache metadata move even with `--no-cache` on the builder stage.

### Image size

| Build | Size |
|-------|------|
| Nix `.#docker` tarball | **2.8 MB** |
| Lab 6 distroless image | **13 MB** |

[`image-size-comparison.txt`](../artifacts/lab11/image-size-comparison.txt)

### Design e–g

**e) What Docker adds non-determinism**

Mutable base images on pull, layer timestamps, file ordering, `RUN` side effects, compiler cache inside BuildKit, and non-pinned package mirrors (`apt`, `go mod download` at build time).

**f) Auditor value of reproducible images**

Anyone can rebuild from source + lockfile and get the **same digest** — ties artifact to source without trusting a registry alone. Signed but non-reproducible images prove publisher identity, not that the binary matches the public source tree.

**g) Nix trade-off**

Reproducibility costs learning curve, store disk, and stricter pinning. `docker build` stays default because Dockerfile is ubiquitous, fast to iterate, and “close enough” for most teams until supply-chain requirements bite.

---

## Bonus — CI reproducibility gate

Workflow: [`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml)

- Two parallel jobs (`build-a`, `build-b`) on fresh `ubuntu-24.04` runners
- `DeterminateSystems/nix-installer-action` + `nix build .#docker`
- `compare-digests` job fails if SHA-256 differ

**Green run:** https://github.com/tdzdslippen/DevOps-Intro/actions/runs/28688551510

**Red run (intentional break):** in `.github/workflows/nix-repro.yml` set `SOURCE_DATE_EPOCH: "1"` **only** in job `build-a` (leave `build-b` at `"0"`). Both jobs must use `nix build .#docker --impure` (otherwise `builtins.getEnv` is ignored in pure mode). Push → `compare-repro-digests` fails → revert `build-a` to `"0"`.

> **Why it stayed green twice:** (1) `created` was hardcoded; (2) even after wiring `getEnv`, plain `nix build` is **pure** — GitHub `env:` never reached the flake. Fix: `--impure` on both build steps.

**Red run URL:** https://github.com/tdzdslippen/DevOps-Intro/actions/runs/28688654619

Log excerpt (green):

```text
digest-a=5804a89d1df139024d6d3335fbeabd21fa80ded1f38e5ebcd6d847d1b1e29fb5
digest-b=5804a89d1df139024d6d3335fbeabd21fa80ded1f38e5ebcd6d847d1b1e29fb5
reproducibility check passed
```

### Design h–j

**h) Laptop vs CI proof**

Laptop proof is anecdotal (hidden local state). CI gives **auditor-visible**, repeated, fork-independent evidence on clean runners.

**i) Why two jobs not one job twice**

Separate runners have separate stores, caches, and environments — catches runner-specific leakage. One job twice might reuse the same store path and hide “first build vs second build” bugs.

**j) `SOURCE_DATE_EPOCH`**

Stops timestamps in archives, gzip headers, and image `created` fields from drifting. We pin `created` in `buildImage` and set `SOURCE_DATE_EPOCH=0` in CI so layer tar metadata stays fixed.
