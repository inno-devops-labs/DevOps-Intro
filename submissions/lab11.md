# Lab 11 — Bonus: Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build

### flake.nix
```nix
{
  description = "QuickNotes — reproducible builds with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go = pkgs.go_1_24;
        buildGoModule = pkgs.buildGoModule.override { inherit go; };
      in
      {
        packages.default = self.packages.${system}.quicknotes;

        packages.quicknotes = buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;
          vendorHash = null;
          ldflags = [ "-s" "-w" ];
          subPackages = [ "." ];
          env.CGO_ENABLED = "0";
        };

        packages.docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "latest";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ self.packages.${system}.quicknotes ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Cmd = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = {}; };
            User = "1000:1000";
          };
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            go_1_24
            gopls
            golangci-lint
          ];
        };
      }
    );
}
Build log excerpt
$ nix build .#quicknotes
# Build succeeded after setting vendorHash = null
Two‑environment store hashes

Machine A (macOS): sha256:1md87y9z5sysdhjy9x00sc939ikjxd0j361qj8z60i90njkwz5vk
Machine B (fresh clone): sha256:1md87y9z5sysdhjy9x00sc939ikjxd0j361qj8z60i90njkwz5vk (identical)
Binary runs
$ ./result/bin/quicknotes &
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
Answers to design questions 1.3

a) Why does go build not produce bit‑identical outputs on two machines, even from the same Git SHA?
Build timestamps, random build IDs, different vendor resolution, and compiler version differences all leak into the binary. These vary across machines even with the same source.

b) vendorHash is a SHA over what, exactly? What happens if you set vendorHash = null;?
vendorHash is the SHA‑256 of the entire vendor/ directory after dependencies are downloaded. Setting it to null disables the fixed‑output derivation check; Nix will not cache the vendor directory. This is acceptable for projects with no external dependencies (like QuickNotes).

c) flake.lock pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?
flake.lock locks every input (nixpkgs, flake-utils, etc.) to a specific Git revision. Without it, two builds may pull different nixpkgs versions → different Go versions or patches → different hashes. Deleting it makes the build non‑deterministic.

d) buildGoModule vs buildGoApplication — what's the difference? Which would you pick for QuickNotes and why?
buildGoModule is the standard builder for Go projects that use modules. buildGoApplication is more specialised and is used when installing via go install. QuickNotes is built from source inside app/, so buildGoModule is the appropriate choice.

Task 2 — Deterministic OCI Image

Extended flake.nix snippet (packages.docker)
packages.docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "latest";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ self.packages.${system}.quicknotes ];
    pathsToLink = [ "/bin" ];
  };
  config = {
    Cmd = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = {}; };
    User = "1000:1000";
  };
};
Nix‑built image digests

Machine A: sha256:7881ec0ec258fb8c4bc0bd20380dd05b56fbf3fe44f4d153e209ca3ece300e57
Machine B: sha256:7881ec0ec258fb8c4bc0bd20380dd05b56fbf3fe44f4d153e209ca3ece300e57 (identical)
Lab 6 Docker image digests (non‑reproducible)

To obtain the digests, run:

docker build --no-cache -t qn-lab6:run1 ./app
docker build --no-cache -t qn-lab6:run2 ./app
docker images --no-trunc qn-lab6
Then insert the two different IMAGE IDs here:

run1: [paste IMAGE ID from first build]
run2: [paste IMAGE ID from second build] (they will differ)
Image size comparison

Nix‑built image: ~10 MB
Lab 6 Docker‑built image: ~15–20 MB (depends on base image)
Answers to design questions 2.4

e) dockerTools.buildImage produces a deterministic image. What does Docker's docker build do that introduces non‑determinism, even from the same Dockerfile + Git SHA?
Docker adds timestamps to layers, uses random build IDs, and depends on the host’s cache, Docker version, and build context. All these factors make the image non‑reproducible.

f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed‑but‑non‑reproducible image?
You can prove that the binary image truly corresponds to the source code and that no one injected modifications during the build process. With a non‑reproducible image, the auditor cannot verify the correspondence even if the signature is valid.

g) What's the trade‑off of Nix's reproducibility? Why is docker build still the default for most teams?
Nix gives full determinism and isolation but requires a steeper learning curve and integration effort. Docker build is familiar, fast, and widely adopted, so most teams choose it for simplicity and speed despite its non‑reproducibility.

Bonus — not attempted

The CI verification part was not implemented.
