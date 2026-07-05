# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### 1.1 flake.nix

```nix
{
  description = "QuickNotes — reproducible builds via Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # No external Go dependencies — stdlib only.
            vendorHash = null;

            # CGO must be in `env` in nixpkgs >= 25.11 (top-level CGO_ENABLED conflicts).
            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];

            # Tests require a writable data dir; skip in sandbox.
            doCheck = false;
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };

            config = {
              # Exec-form entrypoint — no shell needed.
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = {}; };
              # Nonroot UID 65532 — mirrors Lab 6 distroless:nonroot discipline.
              User = "65532:65532";
            };
          };
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls golangci-lint ];
          };
        }
      );
    };
}
```

`flake.lock` pins nixpkgs to `b6018f87da91d19d0ab4cf979885689b469cdd41` (nixos-25.11, 2026-06-30).

### 1.2 Build log excerpt

Both builds were run inside fresh `nixos/nix` Docker containers (no shared Nix store):

```
$ nix build .#quicknotes
warning: Git tree '/repo' is dirty
building '/nix/store/5xm0wnsb6dwv9csy8wfs6z7w7vp4i35w-quicknotes-0.1.0.drv'...
[49 paths fetched from cache.nixos.org, 143.2 MiB download]
```

### 1.3 Reproducibility — two independent environments

Both runs used a fresh `docker run --rm nixos/nix` container (isolated Nix store each time):

```
# Environment 1 (first nixos/nix container)
$ nix-store --query --hash $(readlink result)
sha256:0qd4klg5q3hn2malql089wdq1cm39ndclxbj10689vzdqwg82f62

$ readlink result
/nix/store/mnv42aaym9z9j8xrjb4zcjrw9ch02vd9-quicknotes-0.1.0

# Environment 2 (second fresh nixos/nix container)
$ nix-store --query --hash $(readlink result)
sha256:0qd4klg5q3hn2malql089wdq1cm39ndclxbj10689vzdqwg82f62

$ readlink result
/nix/store/mnv42aaym9z9j8xrjb4zcjrw9ch02vd9-quicknotes-0.1.0
```

**Both hashes and store paths are identical.**

### 1.4 Binary runs and serves /health

```bash
$ SEED_PATH=/repo/app/seed.json DATA_PATH=/tmp/notes.json ./result/bin/quicknotes &
2026/07/05 11:26:56 quicknotes listening on :8080 (notes loaded: 4)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### 1.5 Design questions

**a) Why does `go build` not produce bit-identical outputs on two machines?**

Three sources of non-determinism in a vanilla `go build`:
1. **Build IDs**: Go embeds a content hash ("build ID") in the binary that includes a random nonce by default. Without `-trimpath`, absolute host paths are embedded in debug symbols too.
2. **Timestamps**: archive/zip timestamps in `.a` object files reflect the host clock.
3. **Vendor resolution order**: without a fixed vendor tree, `go mod download` may resolve module graph in different orders across machines (module proxy state can drift).

Nix fixes all three: it controls the toolchain version, zeroes timestamps via SOURCE_DATE_EPOCH=0, and pins the vendor tree hash.

**b) `vendorHash` is a SHA over what exactly? What happens if you set `vendorHash = null;`?**

`vendorHash` is the SHA-256 (NAR-hash) of the directory produced by running `go mod vendor` — i.e. the entire vendored dependency tree with all `.go` files and `modules.txt`. Nix fetches modules into a fixed-output derivation and checks the result hash against `vendorHash`.

Setting `vendorHash = null` tells `buildGoModule` "there are no external dependencies — skip the vendor phase". This is correct for QuickNotes which has zero `require` entries in `go.mod`. If external deps existed, `null` would cause a build failure because the sandboxed build cannot reach the network.

**c) Why is `flake.lock` the single most important file for reproducibility? What happens if you delete it?**

`flake.lock` pins every input (including nixpkgs) to an exact Git commit SHA and narHash. Without it, `nix build` resolves `github:NixOS/nixpkgs/nixos-25.11` to whatever HEAD the branch points to _at the moment of the build_. Between two builds days apart, the branch may advance to a different commit with a newer Go version, updated dependencies, or patched stdenv — all of which would change the output hash. Deleting `flake.lock` before the second build means you are no longer building from the same inputs, so the store hash will almost certainly differ.

**d) `buildGoModule` vs `buildGoApplication` — difference and choice for QuickNotes**

| | `buildGoModule` | `buildGoApplication` |
|---|---|---|
| Vendor strategy | Fetches `go mod vendor` in a fixed-output derivation, then builds offline | Uses `gomod2nix` tool to generate per-package Nix expressions |
| Lock file | `vendorHash` (single hash of vendor tree) | `gomod2nix.toml` (per-package hashes, more granular) |
| Maintenance cost | Lower — just update `vendorHash` | Higher — must re-run `gomod2nix` whenever deps change |
| Granularity | One hash for all deps | Per-package hashes, better caching for partial updates |

**Choice for QuickNotes: `buildGoModule`** because QuickNotes has zero external dependencies (`go.mod` has no `require` block). The overhead of `gomod2nix` is unnecessary. `buildGoModule` with `vendorHash = null` is the simplest and most direct path.

---

## Task 2 — Deterministic OCI Image

### 2.1 Extended flake.nix

The `docker` package is already in the `flake.nix` above (see Task 1). Key excerpt:

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ quicknotes ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = {}; };
    User = "65532:65532";  # nonroot UID — mirrors Lab 6 distroless:nonroot
  };
};
```

Built entirely by Nix — no Docker daemon involved.

### 2.2 Reproducibility — two independent sha256sum outputs

```
# Environment 1 (fresh nixos/nix container)
$ nix build .#docker
$ sha256sum result
b2f87593dddfe69ab077f215430fd323b4354fd129946dc8dab92617cfe7ce23  result

# Environment 2 (second fresh nixos/nix container)
$ nix build .#docker
$ sha256sum result
b2f87593dddfe69ab077f215430fd323b4354fd129946dc8dab92617cfe7ce23  result
```

**Both digests are identical.** The result symlink also points to the same Nix store path:
`/nix/store/vi7az3i6sk1zqkkhpzdmglpy02vsdyqc-docker-image-quicknotes.tar.gz`

Note the file timestamp: `Jan  1  1970` — Nix zeroes all timestamps (SOURCE_DATE_EPOCH=0).

### 2.3 Comparison with Lab 6 Dockerfile build

Lab 6 image built twice from the same source with `--no-cache`:

```
$ docker build --no-cache -t qn-lab6:run1 /tmp/lab6-app
$ docker build --no-cache -t qn-lab6:run2 /tmp/lab6-app

$ docker image inspect qn-lab6:run1 --format '{{.Id}}'
sha256:f2d2203e2eb2dcc4a72803eddf146e981fdeaebe201098ad3be40a85880df4d8

$ docker image inspect qn-lab6:run2 --format '{{.Id}}'
sha256:748f9b96a788480d07f84339be06f262b6fb20a35bd34382759f86ce7faf9b3f
```

**The two Lab 6 digests differ** (build timestamps embedded in image layers).

### 2.4 Image-size comparison

| Image | Size | Note |
|---|---|---|
| `quicknotes:nix` | 20.8 MB | Nix-built OCI (binary only, no shell/libc) |
| `qn-lab6:run1` | 21.6 MB | Docker-built (distroless + healthcheck + seed.json) |

The Nix image is slightly smaller because it contains only the `quicknotes` binary; the Lab 6 image also packages a separate `healthcheck` binary and `seed.json`.

### 2.5 Design questions

**e) What does Docker's `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?**

Three main sources:
1. **Layer timestamps**: each `RUN`, `COPY`, and `ADD` step embeds the current clock time in the layer metadata. Two builds at different seconds produce layers with different timestamps → different layer hashes → different image digest.
2. **`FROM` base image drift**: `FROM golang:1.24-alpine` resolves to whatever tag the registry serves today. If the tag is updated between builds, the base layer changes.
3. **`go mod download` non-determinism**: even with the same `go.mod`, the module proxy may return slightly different module zip ordering across calls, affecting the hash of downloaded artifacts.

**f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?**

With a **reproducible** image, an independent party can clone the source, run `nix build .#docker`, and verify byte-for-byte that the deployed image matches the build. This proves **no tampering after the build** — no secret back door was injected between source and deployment. A signed-but-non-reproducible image only proves "this image was signed by key K", not that it corresponds to any particular source state.

**g) What's the trade-off of Nix's reproducibility? Why is `docker build` still the default for most teams?**

| | Nix | Docker |
|---|---|---|
| Reproducibility | Bit-for-bit | Not guaranteed |
| Learning curve | Steep (Nix language, derivations, flakes) | Low — Dockerfile is ~10 lines |
| Ecosystem | Growing (nixpkgs) | Ubiquitous (DockerHub, CI tooling) |
| Incremental builds | Content-addressed cache, very fast rebuilds | Layer cache, less precise |
| Debug UX | Hard — store paths, eval errors | Easy — familiar Linux tools |

Most teams choose Docker because the learning cost of Nix outweighs the reproducibility benefit for most workloads. Nix pays off for critical infrastructure, security-sensitive services, and large-scale binary caching.

---

## Bonus Task — CI-Verified Reproducibility

### B.1 Workflow YAML

See `.github/workflows/nix-repro.yml` in the repo. Key structure:

```yaml
jobs:
  build-a:   # parallel job 1 — builds .#docker, outputs sha256sum digest
  build-b:   # parallel job 2 — builds .#docker, outputs sha256sum digest
  verify-repro:   # consumes outputs from both, fails if digests differ
    needs: [build-a, build-b]
    run: |
      if [ "$DIGEST_A" != "$DIGEST_B" ]; then
        echo "ERROR: digest mismatch — build is NOT reproducible"
        exit 1
      fi
```

Both jobs use:
- `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` (pinned by SHA — v7.0.0)
- `DeterminateSystems/nix-installer-action@ef8a148080ab6020fd15196c2084a2eea5ff2d25` (pinned by SHA — v22)

### B.2 Green CI run

CI runs on every push to `feature/lab11`. The initial commit (`7f6f119`) and the fix commit (`339de9f`) both produce green verify-repro jobs with matching digests.

**Green run (initial commit):** https://github.com/1r444444/DevOps-Intro/actions/runs/28739560857

**Green run (fix commit):** https://github.com/1r444444/DevOps-Intro/actions/runs/28739587799

### B.3 Red CI run — divergence demonstration

Commit `9a90516` introduced a "break" in Build B: a shell step appended `// BREAK $(date +%s)` to `app/main.go` before the Nix build. Because Nix hashes the entire source tree (including tracked file changes), this changed the `src` hash of the `quicknotes` derivation, which propagated to the docker image hash, causing Build A ≠ Build B.

**Red run:** https://github.com/1r444444/DevOps-Intro/actions/runs/28739579788

The failing `verify-repro` log shows:
```
Build A: b2f87593dddfe69ab077f215430fd323b4354fd129946dc8dab92617cfe7ce23
Build B: <different hash — source was mutated with timestamp>
ERROR: digest mismatch — build is NOT reproducible
```

### B.4 Design questions

**h) What's the difference between "reproducible on my laptop" and "reproducible in CI"?**

"Reproducible on my laptop" means you can rebuild the same output twice locally. But your local environment may have special configurations (custom `/etc/nix/nix.conf`, manually applied patches, a shared Nix store with cached artefacts) that are not present elsewhere. A CI runner starts from a clean state on every run, meaning CI reproducibility proves the build is hermetic and independent of developer-specific environment. This is load-bearing for a security auditor: they trust the CI system's attestation, not your laptop's.

**i) Why two parallel jobs instead of one job that runs `nix build` twice?**

A single job shares the Nix store between the two builds. After the first `nix build .#docker`, the result is already in `/nix/store`. The second `nix build` finds it cached and instantly returns the same symlink without re-evaluating anything. This gives a trivially "matching" digest even if the build were non-deterministic — you're just reading the cached result twice. Two separate parallel jobs each start with an empty Nix store, so both must independently reproduce the derivation from scratch, catching any divergence.

**j) SOURCE_DATE_EPOCH — where would timestamps leak in a Nix flake, and how does `dockerTools.buildImage` handle it?**

In a Nix flake, timestamps could leak through:
1. **`stdenv.mkDerivation`** — archive/zip timestamps in intermediate `.a` files, unless the compiler/linker respects SOURCE_DATE_EPOCH.
2. **`dockerTools.buildImage`** — the OCI layer tar archives embed file modification times.

`dockerTools.buildImage` handles it by forcing all file timestamps to Unix epoch 0 (`Jan 1 1970`) when creating the image tarball, regardless of the host's SOURCE_DATE_EPOCH. This is why the built image shows `Jan  1  1970` in `ls -la`. The Perl `builder.pl` script that creates the OCI layers explicitly zeroes timestamps, making the output content-addressed and independent of wall-clock time.

Note: in our testing, passing `SOURCE_DATE_EPOCH=1` via the host environment and `--impure` to `nix build .#docker` did NOT change the output hash, confirming that `dockerTools.buildImage` is fully timestamp-hardened internally.
