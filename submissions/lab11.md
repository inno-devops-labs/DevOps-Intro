# Lab 11 - Bonus: Reproducible Builds of QuickNotes with Nix

## Overview

This lab adds a Nix flake for QuickNotes. The flake builds the Go binary from `app/`, exposes a development shell, and builds a deterministic OCI image without Docker.

Artifacts:

```text
flake.nix
flake.lock
.github/workflows/nix-repro.yml
submissions/lab11.md
```

## Task 1 - Reproducible Go Build

### Flake

`flake.nix` exposes:

```text
packages.x86_64-linux.quicknotes
packages.x86_64-linux.default
devShells.x86_64-linux.default
```

The package uses `buildGo124Module` because QuickNotes is a normal Go module with a single `go.mod`, no custom build system, and `go.mod` requires Go 1.24. `buildGo124Module` is the Go 1.24-specific form of `buildGoModule`, so it still uses the standard Nix Go module builder while matching the project toolchain.

The binary build sets:

```nix
env.CGO_ENABLED = 0;
ldflags = [
  "-s"
  "-w"
];
vendorHash = null;
```

QuickNotes currently has no external Go dependencies. A trial build with the empty SHA-256 hash failed with:

```text
go: no dependencies to vendor
vendor folder is empty, please set 'vendorHash = null;' in your expression
```

So this repo uses `vendorHash = null;`, which is the nixpkgs-required reproducible setting for a Go module with no dependency vendor tree.

### Build Evidence

Command:

```bash
nix build .#quicknotes
```

Log excerpt:

```text
building '/nix/store/20sshdb4i5m1kf9589fx27n19s56fli3-quicknotes-0.1.0.drv'...
quicknotes> Building subPackage .
quicknotes> Running phase: checkPhase
quicknotes> ok          quicknotes      0.014s
quicknotes> Running phase: installPhase
quicknotes> patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
```

Store hash from environment A:

```bash
nix-store --query --hash "$(readlink result)"
sha256:0jib7gplvq05fivkk6qr4qgq1h09rxgr4qnlhis06k6bhxq596df
```

Store hash from environment B:

```bash
nix-store --query --hash "$(readlink result)"
sha256:0jib7gplvq05fivkk6qr4qgq1h09rxgr4qnlhis06k6bhxq596df
```

### Runtime Proof

Command:

```bash
./result/bin/quicknotes &
curl http://127.0.0.1:8080/health
```

Output:

```text
{"notes":4,"status":"ok"}
2026/07/10 18:29:04 quicknotes listening on :8080 (notes loaded: 4)
```

### Design Questions

#### a) Why does `go build` not produce bit-identical outputs on two machines?

Plain `go build` can include machine-specific or time-specific data unless the build is carefully controlled. Common sources are embedded build IDs, absolute source paths, different toolchain versions, different module resolution timing, environment variables, and timestamps in surrounding packaging steps. Flags such as `-trimpath` and pinned dependencies help, but the whole compiler, dependency graph, and build environment still need to be pinned for a strong reproducibility claim.

#### b) `vendorHash` is a SHA over what, exactly? What happens if it is `null`?

In `buildGoModule`, `vendorHash` is the hash of the vendored Go module dependency tree that Nix creates before compiling the package. It covers the fetched module sources, not the final binary. If the hash is wrong, Nix stops with a mismatch and prints the expected value. If it is `null`, Nix treats the package as having no module vendor fixed-output dependency; that can be acceptable only when there are no external modules. For projects with dependencies, pinning the hash is what prevents undeclared dependency drift.

#### c) Why is `flake.lock` the single most important file?

`flake.lock` pins the exact nixpkgs revision and input metadata used by the build. The flake expression says which channel to follow, but the lockfile says the exact commit. This lab pins `nixos-25.05` to commit `ac62194c3917d5f474c1a844b6fd6da2db95077d`. If the lockfile is deleted before the second build, Nix may resolve the channel again to a different commit, which can change the Go toolchain, Docker tools, dependency builders, and final store paths.

#### d) `buildGoModule` vs `buildGoApplication`

`buildGoModule` is the standard nixpkgs helper for Go modules. It builds from `go.mod`, verifies module dependencies with `vendorHash` when dependencies exist, and fits this repository directly. `buildGoApplication` is commonly used from `gomod2nix`, where dependencies are represented through generated Nix metadata instead of the `buildGoModule` vendor hash flow. I chose the Go 1.24-specific `buildGo124Module` because QuickNotes is small, has no external dependencies today, and needs the Go version declared in `app/go.mod`.

## Task 2 - Deterministic OCI Image

### Image Package

`flake.nix` also exposes:

```text
packages.x86_64-linux.docker
```

It uses `pkgs.dockerTools.buildImage`, copies the Nix-built QuickNotes binary and `seed.json` into the image root, exposes port `8080/tcp`, and runs as nonroot user `65532:65532`.

Runtime proof after `docker load -i quicknotes-nix.tar.gz`:

```text
Loaded image: quicknotes:nix
{"notes":4,"status":"ok"}
2026/07/10 18:25:52 quicknotes listening on :8080 (notes loaded: 4)
```

### Nix Image Digest Proof

Environment A:

```bash
nix build .#docker
sha256sum result
74ca4c07edf3025fdb80202794476029c6c0620c0ea50030028ad717689c49f0  result
```

Environment B:

```bash
nix build .#docker
sha256sum result
74ca4c07edf3025fdb80202794476029c6c0620c0ea50030028ad717689c49f0  result
```

### Image Size Comparison

```text
Nix-built quicknotes:nix: 21.4 MB
Lab 6 quicknotes:lab6: 22.8 MB
```

### Lab 6 Dockerfile Comparison

Commands:

```bash
docker build --no-cache -t qn-lab6:run1 ./app
docker build --no-cache -t qn-lab6:run2 ./app
docker images --no-trunc qn-lab6
```

Output:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED          SIZE
qn-lab6      run2      sha256:6965051bb8546eedc919d47782b1cf316582782614e0917bf27e3e9731b22d73   1 second ago     22.8MB
qn-lab6      run1      sha256:551e5864bfe4947b9073d8ff2807dea4da2f4fc8021e5aa0366b09edf32b17e9   15 seconds ago   22.8MB

sha256:551e5864bfe4947b9073d8ff2807dea4da2f4fc8021e5aa0366b09edf32b17e9 2026-07-10T18:30:15.828837595Z 5711404
sha256:6965051bb8546eedc919d47782b1cf316582782614e0917bf27e3e9731b22d73 2026-07-10T18:30:29.058033973Z 5711401
```

### Design Questions

#### e) What does Docker build do that introduces non-determinism?

Docker builds layers during the build, and those layers can capture timestamps, filesystem metadata, package-manager results, network downloads, and base-image tag movement. Even when the Dockerfile and Git SHA are the same, `FROM golang:1.24-alpine`, `go mod download`, copied file metadata, and layer creation time can vary unless every input and timestamp is pinned or normalized.

#### f) What can a security auditor prove with a reproducible image?

With a reproducible image, an auditor can rebuild from source and verify that the shipped artifact is bit-for-bit the same as the reviewed source and build recipe. A signature alone proves who signed an artifact, but not that the artifact actually came from the visible source. Reproducibility closes that gap: the content itself becomes independently checkable.

#### g) What is the trade-off of Nix reproducibility?

The trade-off is complexity and adoption cost. Nix has its own language, store model, cache model, and debugging style, so the first build can feel slower and less familiar than Docker. Docker remains the default because most teams already know it, hosted builders support it everywhere, and Dockerfiles are easy to read for simple cases. Nix pays off when exact repeatability matters enough to justify the learning curve.

## Bonus Task - CI-Verified Reproducibility

### Workflow

Workflow file:

```text
.github/workflows/nix-repro.yml
```

It runs on push and pull request. Two independent jobs, `build-a` and `build-b`, each install Nix on a fresh GitHub runner, build `.#docker`, and emit `sha256sum result` as a job output. The `compare` job fails if the digests differ.

All third-party actions are pinned by 40-character SHA:

```text
actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5
DeterminateSystems/nix-installer-action@21a544727d0c62386e78b4befe52d19ad12692e3
```

Green CI run:

```text
Pending push. Local branch is intentionally not pushed until approval.
```

Red CI run from deliberate divergence:

```text
Pending push. This requires pushing a deliberately broken commit/run and then a fix, so it is not done before approval.
```

### Design Questions

#### h) Reproducible on my laptop vs reproducible in CI

Local reproducibility proves that the recipe can repeat in one environment. CI reproducibility proves it on fresh, independently provisioned machines with the same committed source and lockfile. For an auditor, CI is stronger evidence because it is automated, reviewable, and less dependent on untracked state from one developer's machine.

#### i) Why two parallel jobs instead of one job that builds twice?

One job that builds twice can accidentally reuse local state, cached outputs, environment variables, or already-normalized artifacts. Two parallel jobs start from separate runners, so matching digests prove the recipe survives independent setup. That catches problems a same-run rebuild could hide.

#### j) Where would `SOURCE_DATE_EPOCH` normally matter?

Timestamps can leak into compiled binaries, archives, and container layers. In this flake, the most likely timestamp-sensitive output is the image layer archive, because a tarball normally records file modification times. `dockerTools.buildImage` normalizes image metadata and uses deterministic timestamps by default, so the final image tarball can be reproduced from the same Nix inputs.
