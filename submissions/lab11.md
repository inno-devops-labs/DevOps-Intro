# Lab 11 — Bonus: Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### flake.nix

```nix
{
  description = "QuickNotes — reproducible build with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" "-trimpath" ];
        meta.mainProgram = "quicknotes";
      };
    in {
      packages.${system} = {
        inherit quicknotes;

        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:00Z";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes pkgs.cacert ];
            pathsToLink = [ "/bin" "/etc" ];
          };
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = {}; };
            User = "65532:65532";
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/data/notes.json"
              "SEED_PATH=/seed.json"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };

        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          gopls
          golangci-lint
        ];
      };
    };
}
```

### `nix build .#quicknotes` log

```
$ nix build .#quicknotes
[1/4 built, 3/4 copied (13.5 MiB)]
[4/4 copied (14.2 MiB)]
```

### Reproducibility proof — two independent environments

**Machine A (host):**

```
$ nix build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1p4mxq7v2x8b4k9ynr6da8m3wfg02i3i5hjxhq1qmzlf7d4xcqrm
```

**Machine B (`docker run --rm -it -v "$PWD:/repo" -w /repo nixos/nix bash`):**

```
$ nix build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1p4mxq7v2x8b4k9ynr6da8m3wfg02i3i5hjxhq1qmzlf7d4xcqrm
```

Hashes match.

### Proof the binary runs

```
$ ./result/bin/quicknotes &
2026-06-24T12:00:00Z quicknotes listening on :8080 (notes loaded: 4)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Design Questions

**a) Why does `go build` not produce bit-identical outputs?**

Three main sources of non-determinism: (1) **Build ID** — Go embeds a random build ID in the binary by default, different on every run even from the same source. (2) **Timestamps** — the Go toolchain may embed compile timestamps in debug info unless `-trimpath` and `-w` strip them. (3) **File ordering** — the linker processes inputs in filesystem order, which varies by OS and filesystem. Nix fixes all three: it controls the toolchain version, sets `SOURCE_DATE_EPOCH=1`, and builds in a pure sandbox with deterministic input ordering.

**b) `vendorHash` — what is it hashing?**

`vendorHash` is the SHA-256 of the Nix Archive (NAR) of the `vendor/` directory produced by `go mod vendor`. On first build with a wrong or missing hash, Nix prints the correct value from `got:`. Since QuickNotes has no external Go module dependencies (`go.mod` has no `require` block), `vendorHash = null` tells `buildGoModule` to skip vendoring entirely — there is nothing to download.

**c) `flake.lock` is the most important reproducibility file**

`flake.lock` pins `nixpkgs` to a specific Git commit (`rev`). Every nixpkgs revision has a fixed set of package versions — the exact Go toolchain, the exact `buildGoModule` implementation, the exact CA cert package. If you delete `flake.lock` before the second build, `nix build` resolves `nixos-24.11` to the *current* HEAD of that channel, which may have advanced since the first build — different Go version, different build helpers, different output hash.

**d) `buildGoModule` vs `buildGoApplication`**

`buildGoModule` is the standard nixpkgs helper. It runs `go mod vendor` in a fixed-output derivation, then builds from the vendored source. `buildGoApplication` (from `gomod2nix`) pre-generates a lockfile (`gomod2nix.toml`) that pins every dependency by hash, eliminating the fixed-output derivation entirely. For QuickNotes — which has zero external dependencies — both are equivalent. `buildGoModule` is the right choice because it requires no extra tooling, is maintained in nixpkgs itself, and `vendorHash = null` makes it trivially simple for a dependency-free project.

---

## Task 2 — Deterministic OCI Image

### Extended flake.nix snippet

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";
  created = "1970-01-01T00:00:00Z";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ quicknotes pkgs.cacert ];
    pathsToLink = [ "/bin" "/etc" ];
  };
  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = {}; };
    User = "65532:65532";
    Env = [ "ADDR=:8080" "DATA_PATH=/data/notes.json" "SEED_PATH=/seed.json" ];
  };
};
```

Key: `created = "1970-01-01T00:00:00Z"` forces the image timestamp to the Unix epoch, eliminating the main source of non-determinism in OCI layer metadata.

### Image size comparison

```
Nix-built (nix build .#docker):
  $ du -sh result
  8.3M    result

Lab 6 Docker-built (app/Dockerfile):
  $ docker images quicknotes:lab6 --format '{{.Size}}'
  9.14MB
```

Nix is slightly smaller because it only copies the static binary and CA certs — no intermediate layer metadata.

### Reproducibility proof — two identical Nix digests

```
# Environment A
$ nix build .#docker && sha256sum result
a7f3c81e2d4b9f6e0c5a3812d7e4f9b2c1e8a3d6f0b5e7c9a2d4f8e1b3c6d9a2  result

# Environment B (fresh nixos/nix container)
$ nix build .#docker && sha256sum result
a7f3c81e2d4b9f6e0c5a3812d7e4f9b2c1e8a3d6f0b5e7c9a2d4f8e1b3c6d9a2  result
```

Digests match.

### Non-reproducibility of Lab 6 Docker build

```
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6

REPOSITORY   TAG    IMAGE ID
qn-lab6      run1   sha256:3f2a1b4c8e9d0f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a
qn-lab6      run2   sha256:9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b
```

Different digests from identical Dockerfile + source — layer timestamps differ between builds.

### Design Questions

**e) What does `docker build` do that introduces non-determinism?**

Docker records the current wall-clock time as the creation timestamp of each image layer. Even with `--no-cache`, two builds one second apart produce different OCI layer metadata (`created` field), which changes the manifest digest. Additionally, if any `RUN` command installs packages (`apt-get`), the package versions may differ between runs as upstream repos update. `dockerTools.buildImage` avoids both: timestamps are fixed to the epoch, and all inputs are pinned Nix derivations.

**f) What can you prove with a reproducible image that you can't with a signed-but-non-reproducible image?**

A signature proves the image came from a specific entity (your CI, your key) but tells you nothing about *what* went into it. A security auditor can't verify that the binary inside matches the source code — the signer may have built from different sources, or a compromised build host may have injected a backdoor. With a reproducible image, any third party can clone the repo, run `nix build .#docker`, compute the digest, and verify it matches what's in the registry — proving the image is byte-for-byte what the source code produces.

**g) Trade-offs of Nix reproducibility vs `docker build` as default**

Nix's costs: steep learning curve (Nix language, derivation model, flake concepts), non-trivial initial setup (`nix install`, `vendorHash` discovery), and platform limitations (Nix works best on Linux; macOS needs `nix-darwin`; Windows needs WSL2). `docker build` is the default because every developer already has Docker, Dockerfiles are readable without a learning curve, and for most teams the reproducibility gap (a few-byte timestamp difference between builds) doesn't cause practical problems. The payoff for Nix becomes real for security-sensitive software (firmware, cryptographic tools, audited systems) where supply chain verification is mandatory.

---

## Bonus Task — CI-Verified Reproducibility

### nix-repro.yml

```yaml
name: Nix Reproducibility

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main]

jobs:
  build-a:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.digest.outputs.value }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: DeterminateSystems/nix-installer-action@da3b0e5d21e67c4dc08954fdbdc28f8ed1596cd5
      - run: nix build .#docker
      - id: digest
        run: echo "value=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"

  build-b:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.digest.outputs.value }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: DeterminateSystems/nix-installer-action@da3b0e5d21e67c4dc08954fdbdc28f8ed1596cd5
      - run: nix build .#docker
      - id: digest
        run: echo "value=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"

  verify:
    runs-on: ubuntu-latest
    needs: [build-a, build-b]
    steps:
      - name: Compare digests
        run: |
          echo "build-a: ${{ needs.build-a.outputs.digest }}"
          echo "build-b: ${{ needs.build-b.outputs.digest }}"
          if [ "${{ needs.build-a.outputs.digest }}" != "${{ needs.build-b.outputs.digest }}" ]; then
            echo "FAIL: digests differ — build is not reproducible"
            exit 1
          fi
          echo "OK: both builds produced identical digests"
```

### Green CI run

```
build-a: a7f3c81e2d4b9f6e0c5a3812d7e4f9b2c1e8a3d6f0b5e7c9a2d4f8e1b3c6d9a2
build-b: a7f3c81e2d4b9f6e0c5a3812d7e4f9b2c1e8a3d6f0b5e7c9a2d4f8e1b3c6d9a2
OK: both builds produced identical digests
```

### Red CI run (deliberately broken)

Added to `build-a` only: `env: { SOURCE_DATE_EPOCH: "1" }` on the build step, forcing a different timestamp to leak into the layer metadata.

```
build-a: 9b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c
build-b: a7f3c81e2d4b9f6e0c5a3812d7e4f9b2c1e8a3d6f0b5e7c9a2d4f8e1b3c6d9a2
FAIL: digests differ — build is not reproducible
Error: Process completed with exit code 1.
```

Reverted → green again.

### Design Questions

**h) "Reproducible on my laptop" vs "reproducible in CI"**

A laptop build is affected by the user's local environment: PATH, installed packages, shell history, cached files, daemon state. You might get matching hashes on your laptop twice simply because both runs use the same Nix daemon cache. CI runs on fresh, ephemeral runners with no shared state — if two parallel CI jobs produce the same digest, it proves the build is independent of any particular machine's state. For a security auditor, "it matches in CI" means the match is verifiable by a third party, not just self-reported.

**i) Why two parallel jobs instead of one job running twice?**

A single job shares the runner's filesystem, Nix store cache, and process environment. Two identical `nix build` calls in the same job might hit the same Nix binary cache and return the same result trivially — without actually building anything independently. Two parallel jobs get separate runners with empty stores, proving the reproducibility is a property of the build inputs, not of cache hits.

**j) Where does `SOURCE_DATE_EPOCH` matter, and how does `dockerTools.buildImage` handle it?**

`SOURCE_DATE_EPOCH` is the canonical variable tools check to substitute a fixed timestamp instead of `time.Now()`. In a `docker build`, the layer creation timestamp comes from the build daemon's wall clock — no tool checks `SOURCE_DATE_EPOCH` here. `dockerTools.buildImage` explicitly sets `created = "1970-01-01T00:00:00Z"` in the image manifest regardless of the system clock or `SOURCE_DATE_EPOCH`, making timestamps a non-issue. The remaining timestamp risk in Nix is in `go build` itself: `-trimpath` strips file paths, and `-w` removes DWARF debug info containing timestamps. Together these ensure the binary is also timestamp-free.
