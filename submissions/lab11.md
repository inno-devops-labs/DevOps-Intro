# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### flake.nix

```nix
{
  description = "QuickNotes - reproducible build with Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;
          vendorHash = null;
          subPackages = [ "." ];
          ldflags = [ "-s" "-w" ];
        };
        default = self.packages.${system}.quicknotes;
      };
      
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ go gopls golangci-lint ];
      };
    };
}

flake.lock

Generated automatically by Nix during the first build. Committed to the repository to pin all inputs, including the exact nixpkgs revision.
Build Log Excerpt

First build attempt with vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" failed with:
vendor folder is empty, please set 'vendorHash = null;'
After changing vendorHash to null, the build succeeded.

Reproducibility Verification

Two independent builds produced identical store hashes:

    Build 1: sha256:1njb0x7ljj9qr3w33614qanjmpi1bym0zp1i31309anisli7lm8n

    Build 2: sha256:1njb0x7ljj9qr3w33614qanjmpi1bym0zp1i31309anisli7lm8n

The hashes match.
Binary Works

$ ./result/bin/quicknotes &
$ curl http://localhost:8080/health
{"notes":0,"status":"ok"}

Design Questions

a) Why does go build not produce bit-identical outputs on two machines, even from the same Git SHA?

Go builds embed timestamps and build IDs into the binary. Different Go versions, filesystem ordering, and dependency resolution also affect the output. Without vendoring, network fetches can introduce variations.

b) vendorHash is a SHA over what, exactly? What happens if you set vendorHash = null;?

vendorHash is a SHA-256 hash of all vendored Go dependencies. Setting it to null disables hash verification. This works for projects without external dependencies but reduces reproducibility guarantees for projects that have them.

c) flake.lock pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?

flake.lock locks exact revisions of all inputs, ensuring everyone uses the same package versions. Without it, a second build would fetch the latest channel revision, introducing version differences that break reproducibility.

d) buildGoModule vs buildGoApplication — what's the difference? Which would you pick for QuickNotes and why?

buildGoModule is the modern function for Go projects with module support. buildGoApplication is legacy and predates Go modules. I chose buildGoModule because QuickNotes uses Go modules and this provides better reproducibility through vendorHash.


## Task 2 — Deterministic OCI Image

### Nix-built Image

The flake was extended with a `dockerImage` output using `pkgs.dockerTools.buildImage`. The image bundles the statically compiled QuickNotes binary, sets `/bin/quicknotes` as the entrypoint, exposes port 8080, and runs under the `nonroot` user.

```nix
dockerImage = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "latest";
  config = {
    Cmd = [ "${self.packages.${system}.quicknotes}/bin/quicknotes" ];
    ExposedPorts = {
      "8080/tcp" = {};
    };
    User = "nonroot:nonroot";
  };
};

Building the image is a pure Nix operation:
nix build .#dockerImage

The result is a .tar.gz archive that can be loaded with docker load.
Reproducibility Verification

Two independent builds of the Nix OCI image produced identical digests:

    Build 1: 5b1f20761c5be75aa3d0c7dd9f62d1b807224be5517002eb8c7254811a8b26f1

    Build 2: 5b1f20761c5be75aa3d0c7dd9f62d1b807224be5517002eb8c7254811a8b26f1

The digests match exactly, confirming that the Nix-built image is fully reproducible.
Comparison with Lab 6 (Docker build)

The same source code built with docker build --no-cache produced different image IDs on two consecutive runs:

    Lab 6 run 1: sha256:14a8...

    Lab 6 run 2: sha256:9f3c...

The digests differ, demonstrating that the standard Docker build process is non-deterministic, primarily due to timestamps embedded in layers and file metadata.

Design Questions

e) Why is docker build non-deterministic even from the same Dockerfile + Git SHA?

Docker layers include creation timestamps and file modification times. Each layer’s hash depends on its full metadata, so any timestamp change produces a different digest. Network fetches and cache behaviour can also introduce variation.

f) What can a security auditor prove with a reproducible image that they cannot prove with a signed-but-non-reproducible image?

A reproducible image allows the auditor to independently rebuild the image from source and verify byte-for-byte equivalence with the production image. A signature only confirms who built the image, not that the image actually corresponds to the reviewed source code.

g) What is the trade-off of Nix's reproducibility? Why is docker build still the default for most teams?

Nix builds are slower, require learning a new language (the Nix DSL), and consume more disk space. docker build is simpler to write, benefits from layer caching, and has a much larger ecosystem of pre-built images and community tooling.

## Bonus Task — CI-Verified Reproducibility

**h) What's the difference between "reproducible on my laptop" and "reproducible in CI" that makes the CI proof load-bearing for a security auditor?**

A laptop build depends on local configuration, environment variables, and system state that cannot be independently verified or reproduced by others. CI provides a standardized, controlled, and auditable environment that can be recreated by anyone. For an auditor, CI serves as independent, third-party verification that the build process is deterministic and not dependent on a single machine's unique state.

**i) Why two parallel jobs instead of one job that runs `nix build` twice? What could a single-job two-build comparison miss?**

Parallel jobs on fresh runners eliminate cross-contamination from shared caches, build artifacts, or system state between builds. A single job running two builds sequentially might reuse cached results from the first build, hiding non-determinism that would appear on a clean system. Parallel jobs ensure both builds start from identical, isolated environments, providing a stronger guarantee of reproducibility.

**j) `SOURCE_DATE_EPOCH` is the canonical env var for forcing build timestamps. Where in your Nix flake would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?**

Timestamps can leak into Go binaries through embedded build times and into Docker layers through file metadata (creation times, modification times). `dockerTools.buildImage` respects `SOURCE_DATE_EPOCH` by using it to set deterministic timestamps for all files and layers in the image, ensuring that layer hashes remain consistent across builds. In our flake, we also use `ldflags = [ "-s" "-w" ]` to strip debug information, which removes additional timestamp-related metadata from the binary.

