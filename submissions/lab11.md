# Lab 11 - Reproducible QuickNotes Builds with Nix

## Environment

The host Docker Desktop/WSL setup was unavailable, so I used the existing Vagrant VM and ran Nix in two fresh `nixos/nix:2.24.11` containers. The repository was copied to `/tmp/qn` inside each Nix container before building so Nix did not try to resolve the Windows worktree `.git` pointer.

`flake.lock` pins nixpkgs to:

```text
NixOS/nixpkgs b6018f87da91d19d0ab4cf979885689b469cdd41
narHash sha256-twXPFqFsrrY5r28Zh7Homgcp2gUMBgQ6WDS98Q/3xFI=
original ref nixos-25.11
```

## flake.nix

```nix
{
  description = "Reproducible QuickNotes build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          buildGo124Module = pkgs.buildGoModule.override {
            go = pkgs.go_1_24;
          };

          quicknotes = buildGo124Module {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./app;
            vendorHash = null;

            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];

            postInstall = ''
              install -Dm0644 seed.json $out/share/quicknotes/seed.json
            '';
          };

          imageRoot = pkgs.buildEnv {
            name = "quicknotes-root";
            paths = [ quicknotes ];
            pathsToLink = [ "/bin" "/share" ];
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            created = "1970-01-01T00:00:01Z";

            copyToRoot = imageRoot;
            extraCommands = ''
              mkdir -m 1777 tmp
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/tmp/notes.json"
                "SEED_PATH=/share/quicknotes/seed.json"
              ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
              User = "65532:65532";
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.go_1_24
            pkgs.gopls
            pkgs.golangci-lint
          ];
        };
      });
    };
}
```

I used `buildGoModule` because QuickNotes is a small single-module Go service. The first fake-hash build reported that there are no Go dependencies to vendor, so `vendorHash = null;` is the correct fixed value for this application.

## Task 1 - Nix Go Build

Build log excerpt:

```text
copying path '/nix/store/kqjnjg9pyn17qiwgnalfp98kpkpi3g7v-go-1.24.13' from 'https://cache.nixos.org'...
building '/nix/store/8v6fhgp4aka9a5rlmzhkrikiv1ch2zc9-quicknotes-0.1.0.drv'...
```

Two independent Nix containers produced the same store path and hash:

```text
# environment A
store_path=/nix/store/98i7a6iag94ldaz6jrasjgsbrpis0fad-quicknotes-0.1.0
sha256:1gip31pk535gd24ljiwqfhqfxjvlp8cnqmshdprmnpimp88vjksr

# environment B
store_path=/nix/store/98i7a6iag94ldaz6jrasjgsbrpis0fad-quicknotes-0.1.0
sha256:1gip31pk535gd24ljiwqfhqfxjvlp8cnqmshdprmnpimp88vjksr
```

Runtime proof:

```text
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}
```

## Task 1 Design Questions

a) Plain `go build` can vary between machines because the compiler/toolchain version, standard library build cache, absolute source paths, module download state, embedded build IDs, linker behavior, and environment can differ. `-trimpath` and fixed `-ldflags` help, but they do not pin the whole build graph the way Nix does.

b) `vendorHash` is the hash of the dependency vendor tree produced by `buildGoModule` from `go.mod`/`go.sum`. If it is wrong, Nix refuses to build and prints the expected hash. If it is `null`, Nix skips vendored dependency hashing. That is only correct here because QuickNotes has no third-party Go module dependencies.

c) `flake.lock` pins the exact nixpkgs revision and input hashes. Without it, a later build may resolve `nixos-25.11` to a newer revision with a different Go compiler, libc, hooks, or `dockerTools`, producing different outputs even when the app source did not change.

d) `buildGoModule` is the standard nixpkgs builder for Go modules and fits a normal Go service like QuickNotes. `buildGoApplication` is commonly used from `garnix/go-nix` workflows and can model Go builds differently, especially around vendoring and module handling. I picked `buildGoModule` because it is native to nixpkgs, simple, and enough for this repository.

## Task 2 - Deterministic OCI Image

Docker image build log excerpt:

```text
building '/nix/store/d0gcakxdrw1n10f8yzk9wp7nnwp6284r-quicknotes-root.drv'...
building '/nix/store/72c4mhfm644hgvwankjax800jmlq83xd-docker-layer-quicknotes.drv'...
building '/nix/store/7hd8jkwd6cvd6wyrxplxmnl78b5xsr2z-docker-image-quicknotes.tar.gz.drv'...
```

Two independent Nix containers produced the same image tarball digest:

```text
# environment A
702a292e3a7d2d7c42d20baec9cb7377db5251665b1dcb2b7851e8fb68bf4899  result

# environment B
702a292e3a7d2d7c42d20baec9cb7377db5251665b1dcb2b7851e8fb68bf4899  result
```

The image is loadable and serves health checks:

```text
Loaded image: quicknotes:nix
{"notes":4,"status":"ok"}
```

Image size comparison:

```text
quicknotes:nix tarball: 5,495,701 bytes
quicknotes:nix loaded Docker image: 32,656,379 bytes
qn-lab6:run1 loaded Docker image: 22,550,414 bytes
qn-lab6:run2 loaded Docker image: 22,550,423 bytes
```

Fresh Lab 6-style Docker builds with `--no-cache` produced different image IDs:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED          SIZE
qn-lab6      run2      sha256:0716196fc64b3779e81506e0ec0629db0170165dbc6c5153f65fa9d291c960b5   2 seconds ago    22.6MB
qn-lab6      run1      sha256:b10fb0efc92225e43867fdfbe2390ff89516bed9f39db39918f49193e00013cc   30 seconds ago   22.6MB
```

## Task 2 Design Questions

e) `docker build` records changing metadata such as layer creation times, config timestamps, provenance/attestation metadata, and filesystem metadata from each build step. It can also vary with mutable base image tags, network fetches, and host/buildkit behavior. Nix builds the closure from pinned inputs and `dockerTools.buildImage` lets us set a fixed creation timestamp.

f) A reproducible image lets an auditor rebuild from source and prove that the published artifact corresponds to the reviewed source and pinned dependencies. A signed non-reproducible image proves who signed it, but not that an independent rebuild from the same source yields the same bytes.

g) The trade-off is complexity and onboarding cost. Nix asks teams to learn the store model, flakes, lockfiles, derivations, and cache behavior. `docker build` remains the default because it is familiar, widely supported by CI/CD systems, easier to debug for many developers, and has broad ecosystem documentation.

## Bonus Task

The CI reproducibility bonus was not attempted in this PR. This submission covers Task 1 and Task 2.
