# Lab 11 - Bonus: Reproducible Builds of QuickNotes with Nix

## Overview

This lab adds a Nix flake for QuickNotes. The flake builds the Go binary reproducibly and also builds a deterministic Docker/OCI image using Nix `dockerTools.buildImage`.

The proof is based on two independent Nix store volumes:

```text
lab11-nix-store-a
lab11-nix-store-b
```

These act as two isolated build environments.

---

# Task 1 - Reproducible Go Build via Nix Flake

## Files added

```text
flake.nix
flake.lock
```

The `flake.lock` file is committed so the exact nixpkgs revision is pinned.

---

## flake.nix

```nix
{
  description = "Reproducible QuickNotes build with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = system: import nixpkgs {
        inherit system;
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./.;
            modRoot = "app";

            # QuickNotes has no external Go module dependencies to vendor.
            vendorHash = null;

            env = {
              CGO_ENABLED = "0";
            };

            ldflags = [
              "-s"
              "-w"
            ];

            meta = {
              mainProgram = "quicknotes";
            };
          };

          quicknotesRoot = pkgs.runCommand "quicknotes-root" {} ''
            mkdir -p $out/bin

            cp ${quicknotes}/bin/quicknotes $out/bin/quicknotes

            chmod 0555 $out/bin
            chmod 0555 $out/bin/quicknotes
          '';

          quicknotesImage = pkgs.dockerTools.buildImage {
            name = "quicknotes-nix";
            tag = "0.1.0";

            created = "1970-01-01T00:00:01Z";

            copyToRoot = quicknotesRoot;

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = {
                "8080/tcp" = {};
              };
              User = "65532:65532";
              WorkingDir = "/";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/dev/shm/notes.json"
                "SEED_PATH=/dev/shm/seed.json"
              ];
            };
          };
        in
        {
          quicknotes = quicknotes;
          default = quicknotes;
          docker = quicknotesImage;
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              golangci-lint
            ];
          };
        });
    };
}
```

---

## Notes on `vendorHash`

The initial build showed that QuickNotes has no external Go module dependencies to vendor:

```text
go: no dependencies to vendor
vendor folder is empty, please set 'vendorHash = null;' in your expression
```

Because there are no vendored dependencies, the flake uses:

```nix
vendorHash = null;
```

---

## Build command

```powershell
docker run --rm `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  nix --extra-experimental-features "nix-command flakes" build .#quicknotes
```

Build excerpt:

```text
building '/nix/store/wq8zpifk317pzip0v4y1dqzfi8a8v386-quicknotes-0.1.0.drv'...
```

---

## Reproducibility proof

Environment A:

```powershell
docker run --rm `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  nix-store --query --hash ./result
```

Output:

```text
sha256:1sdf3srfjfw91r0cbwx5pnhlzhamyy3idq7d3v3acscvz37pd3zs
```

Environment B:

```powershell
docker run --rm `
  -v lab11-nix-store-b:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  nix-store --query --hash ./result
```

Output:

```text
sha256:1sdf3srfjfw91r0cbwx5pnhlzhamyy3idq7d3v3acscvz37pd3zs
```

The two independent builds produced the same Nix store hash.

---

## Runtime proof for Nix-built binary

Command:

```powershell
docker run -d `
  --name qn-nix-bin `
  -p 19080:8080 `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  -e ADDR=:8080 `
  -e DATA_PATH=/tmp/notes.json `
  -e SEED_PATH=/tmp/seed.json `
  nixos/nix `
  ./result/bin/quicknotes

Start-Sleep -Seconds 3

curl.exe -s http://localhost:19080/health
curl.exe -s http://localhost:19080/notes

docker rm -f qn-nix-bin
```

Output:

```json
{"notes":0,"status":"ok"}
[]
```

---

## Task 1 design questions

### a) Why does plain `go build` not always produce bit-identical outputs on two machines?

Plain `go build` can include build IDs, local path information, timestamps, and environment-specific metadata. It can also resolve dependencies differently if module cache state, proxy behavior, or toolchain versions differ.

Even if the Git SHA is the same, two machines can have different Go versions, dependency caches, module proxy responses, or filesystem paths. Those small differences can affect the final binary.

Nix reduces this by pinning the toolchain, source input, environment, and dependency resolution.

### b) What is `vendorHash` a hash over? What happens if `vendorHash = null;`?

For `buildGoModule`, `vendorHash` normally hashes the fixed-output dependency vendor tree produced from `go.mod` and `go.sum`. It proves that Go dependencies are exactly what the flake expects.

If `vendorHash = null;`, Nix does not expect a vendored dependency tree. In this project, that is correct because QuickNotes has no external Go dependencies to vendor.

If the project had real external dependencies and `vendorHash` were null incorrectly, the build would fail or would not provide the intended dependency reproducibility guarantee.

### c) Why is `flake.lock` the most important file for reproducibility?

`flake.lock` pins the exact nixpkgs revision and input hashes. Without it, `nixos-unstable` could resolve to a newer revision on a later build.

If `flake.lock` is deleted before the second build, Nix may generate a new lockfile pointing to a different nixpkgs revision. That can change the Go toolchain, build scripts, Docker tools, base packages, and output hashes.

### d) `buildGoModule` vs `buildGoApplication`: what is the difference, and which is better here?

`buildGoModule` is the standard nixpkgs builder for Go modules. It works directly with `go.mod`, supports `vendorHash`, and is widely used in nixpkgs packaging.

`buildGoApplication` is associated with gomod2nix-style workflows, where dependencies are converted into Nix expressions. It can give more detailed dependency pinning but requires extra generated files and workflow complexity.

For QuickNotes, `buildGoModule` is the better choice because the app is small, has no external dependencies to vendor, and the lab specifically allows `buildGoModule`.

---

# Task 2 - Deterministic OCI Image

## Image output

The flake exposes:

```text
.#docker
```

Build command:

```powershell
docker run --rm `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  nix --extra-experimental-features "nix-command flakes" build .#docker
```

The image is built without Docker. Docker is only used here as a convenient container for running Nix on Windows.

---

## OCI image reproducibility proof

Environment A:

```powershell
docker run --rm `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  sha256sum ./result
```

Output:

```text
6094d07581fa914480294417be83dea768387e833295aed026c8703bcf1b1dda  ./result
```

Environment B:

```powershell
docker run --rm `
  -v lab11-nix-store-b:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  sha256sum ./result
```

Output:

```text
6094d07581fa914480294417be83dea768387e833295aed026c8703bcf1b1dda  ./result
```

The two independent Nix image builds produced the same SHA-256 tarball digest.

---

## Loadable image proof

Commands:

```powershell
docker run --rm `
  --user 0 `
  -v lab11-nix-store-a:/nix `
  -v "${PWD}:/repo" `
  -w /repo `
  nixos/nix `
  cp -L ./result /repo/quicknotes-nix-fixed.tar

docker load -i .\quicknotes-nix-fixed.tar

docker images --no-trunc quicknotes-nix
```

Output:

```text
Loaded image: quicknotes-nix:0.1.0

REPOSITORY       TAG       IMAGE ID                                                                  CREATED        SIZE
quicknotes-nix   0.1.0     sha256:a11e6af617aa91dd6fabd16f6b3f3a3f7f79eb313869247c18eecd6e72a7a436   56 years ago   22MB
```

---

## Nix image runtime proof

Command:

```powershell
docker run -d --name qn-nix-image -p 19180:8080 quicknotes-nix:0.1.0

Start-Sleep -Seconds 5

docker ps --filter "name=qn-nix-image"
docker logs qn-nix-image

curl.exe -s http://localhost:19180/health
curl.exe -s http://localhost:19180/notes

docker rm -f qn-nix-image
```

Output:

```text
CONTAINER ID   IMAGE                  COMMAND             CREATED         STATUS         PORTS                                           NAMES
1bd243de7f42   quicknotes-nix:0.1.0   "/bin/quicknotes"   6 seconds ago   Up 5 seconds   0.0.0.0:19180->8080/tcp, [::]:19180->8080/tcp   qn-nix-image

2026/07/14 02:22:16 quicknotes listening on :8080 (notes loaded: 0)

{"notes":0,"status":"ok"}
[]
```

The image runs as nonroot using:

```nix
User = "65532:65532";
```

It writes runtime data under `/dev/shm`, which is writable at runtime and avoids requiring a mutable root filesystem.

---

## Image size comparison

Nix-built image:

```text
quicknotes-nix:0.1.0
Image ID: sha256:a11e6af617aa91dd6fabd16f6b3f3a3f7f79eb313869247c18eecd6e72a7a436
Size: 22MB
```

Lab 6 Dockerfile builds:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED                  SIZE
qn-lab6      run2      sha256:dd715a157cdf56b6da294a59ee362c2102408d961395a1177b4aeb6d33c6ac22   Less than a second ago   23.5MB
qn-lab6      run1      sha256:c5cdf8733e35236cf36f0d69c5093d9faf2d29b20d9e268925fb3379c3c86b20   8 seconds ago            23.5MB
```

The two Lab 6 Docker builds produced different image IDs even though they used the same Dockerfile and source tree. The Nix image tarball digest matched across independent builds.

---

## Task 2 design questions

### e) What does `docker build` do that introduces nondeterminism?

`docker build` creates layers with metadata such as timestamps, layer creation times, build cache behavior, file ordering, and base image state. If the Dockerfile installs packages, package repository state can also change over time.

Even when the Dockerfile and Git SHA are the same, two builds may differ because Docker records build-time metadata in image layers and config. BuildKit improves many things, but the default Docker workflow is not primarily designed around bit-identical output.

### f) What can a security auditor prove with a reproducible image that they cannot prove with a signed but non-reproducible image?

A signed non-reproducible image proves who signed the image, but not necessarily that the image corresponds exactly to the reviewed source code.

A reproducible image lets an auditor independently rebuild from the same source and compare the digest. If the digest matches, the auditor can prove that the distributed artifact was produced from the reviewed source and pinned dependencies.

Signing answers “who published this?” Reproducibility helps answer “is this artifact exactly what the source says it should be?”

### g) What is the trade-off of Nix reproducibility? Why is Docker still the default?

Nix gives strong reproducibility, pinned inputs, isolated builds, and deterministic artifacts. The trade-off is complexity. Teams need to learn the Nix language, maintain flakes, understand the Nix store, and debug unfamiliar errors.

Docker remains the default because it is easier to teach, widely supported by CI/CD platforms, and already integrated into most deployment systems. It is less reproducible by default, but it is familiar and operationally convenient.

---

# Bonus Task - CI-Verified Reproducibility

The CI bonus task was not attempted.

No `.github/workflows/nix-repro.yml` workflow was added, and no green/red CI reproducibility runs were collected.

---

# Final status

Task 1 complete:

```text
flake.nix builds QuickNotes with Nix
flake.lock pins nixpkgs
CGO_ENABLED=0 is set
ldflags -s -w are used
devShell includes go, gopls, and golangci-lint
two independent builds produced identical store hashes
the Nix-built binary runs and serves /health
```

Task 2 complete:

```text
flake.nix exposes .#docker
dockerTools.buildImage produces a loadable OCI image tarball
image runs as nonroot
image exposes 8080/tcp
two independent image builds produced identical SHA-256 tarball digests
Nix image was compared against two non-cached Lab 6 Docker builds
```

Bonus not attempted.