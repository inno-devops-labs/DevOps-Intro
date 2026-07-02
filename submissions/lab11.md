# Lab 11 Submission

## Task 1 — Reproducible Go Build (4 pts)

### 1.1 flake.nix

```nix
{
  description = "QuickNotes — reproducible Go build";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      quicknotes = pkgs.buildGo126Module {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        ldflags = [ "-s" "-w" ];
        doCheck = false;
      };
      default = self.packages.${system}.quicknotes;
    };
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [ go gopls golangci-lint ];
    };
  };
}

1.2 Build & Run

Binary built successfully via nix build .#quicknotes. Running ./result/bin/quicknotes & starts the server on port 8080. curl localhost:8080/health returns {"notes":0,"status":"ok"}. Build log confirms no errors, binary is statically linked.
1.3 Store Hash

First build: sha256:07bbhadc3r13ay5ymx4a26az3q157l7x3knf3w1kh1019x2334ax

Second build (after nix store gc): sha256:07bbhadc3r13ay5ymx4a26az3q157l7x3knf3w1kh1019x2334ax

1.4 Design Questions

a) Why does go build not produce bit-identical outputs on two machines, even from the same Git SHA?
Go embeds variable information into every binary including the build ID which is a random hash, filesystem paths from the machine where compilation happened, and timestamps. Even with the same source code and same Go version, two different machines will produce different build IDs and may have slightly different module cache states. The Go toolchain does not guarantee bitwise reproducibility by default.

b) vendorHash is a SHA over what, exactly? What happens if you set vendorHash = null;?

vendorHash is a SHA-256 hash computed over the entire content of all Go module dependencies as specified in go.sum. It captures the exact versions and contents of every transitive dependency. When set to null, Nix attempts to compute it during the first build and fails with a hash mismatch error, printing the correct hash value that should be pasted into the flake.

c) flake.lock pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?

flake.lock records the exact Git revision and SHA-256 hash of every input including nixpkgs. This means every build uses precisely the same versions of Go, glibc, and all other build dependencies. Without the lockfile, Nix would fetch whatever is the latest commit on the nixos-unstable branch at that moment, which could be a completely different set of packages with a different Go version, different compiler flags, and different system libraries. Two builds without the lockfile would almost certainly produce different binaries.

d) buildGoModule vs buildGoApplication — what's the difference? Which would you pick for QuickNotes and why?

buildGoModule is designed for building a single Go module with a go.mod file. It handles dependency management through vendorHash. buildGoApplication is for larger projects that contain multiple Go modules or need custom build steps. QuickNotes is a single module application with no submodules, so buildGo126Module (the versioned variant of buildGoModule) is the correct and simplest choice.
###Task 2 — Deterministic OCI Image (4 pts)
2.1 Extended flake.nix

docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";
  copyToRoot = pkgs.buildEnv {
    name = "quicknotes-root";
    paths = [ self.packages.${system}.quicknotes ];
    pathsToLink = [ "/bin" ];
  };
  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = {}; };
    User = "65534:65534";
  };
};

2.2 Build & Load

Image built via nix build .#docker producing a gzipped tarball. docker load < result successfully imports the image as quicknotes:nix. Container starts and the binary begins execution, confirmed by docker logs showing the application startup message. Container runs as non-root user 65534 per the security hardening requirement.
2.3 SHA256 Digest

First build: 0dd1e8c60570d6aeb866c1c8fcda84b19baa14c4f43ce659189221144fdd83f7
Second build (after `nix store gc`): 0dd1e8c60570d6aeb866c1c8fcda84b19baa14c4f43ce659189221144fdd83f7

Docker build (non-reproducible, Lab 6):
- run1: sha256:e2faba7b1c4cdd3e640642dbddc977e4478866d042b34a87911f3247995b25c8
- run2: sha256:da6f85c7d92232d88ab7a01bc2b187c4fb7431926b1213f7f82346d4a6d6c958

Nix builds are identical; Docker builds differ each time.

2.4 Design Questions

e) dockerTools.buildImage produces a deterministic image. What does Docker's docker build do that introduces non-determinism, even from the same Dockerfile + Git SHA?

Docker build introduces non-determinism through several mechanisms. Layer timestamps are set to the current wall clock time when each RUN or COPY instruction executes. The COPY instruction preserves filesystem modification times from the host. Base image tags like alpine:3.21 are mutable pointers that may resolve to different image digests over time as security patches are released. Package managers like apk or apt fetch whatever version is current at build time rather than a pinned version. All of these mean that running docker build twice from the same Dockerfile typically produces images with different SHA-256 digests.
f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?

A signed image proves authenticity — it tells the auditor who built it and that the image was not tampered with after signing. A reproducible image proves correspondence — it tells the auditor that the binary they can see was actually produced from the source code they can read. With only signing, you must trust that the builder did not insert malicious code before signing. With reproducibility, anyone can independently verify that a given source revision produces a bitwise identical binary, which eliminates the need to trust the build infrastructure itself.

g) What's the trade-off of Nix's reproducibility? Why is docker build still the default for most teams?

Nix requires a significant upfront investment in learning a new language, tooling, and mental model. Every dependency must be explicitly declared and pinned. Docker build is immediate and familiar — most developers already know how to write a Dockerfile, and it works the same way everywhere. Teams optimize for developer velocity and onboarding speed. The reproducibility that Nix provides becomes critically important only when you need it for compliance, security audits, or debugging production incidents where you must recreate the exact binary from months ago.

