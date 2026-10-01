# Lab 11 — Bonus: Reproducible Builds of QuickNotes with Nix

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab11

## Environment note

macOS (Apple M3 Pro, arm64) cannot natively build Linux OCI images, and Nix
store paths for `aarch64-darwin` differ from Linux — so a darwin build could
never match a Linux build. All Nix work is therefore done inside Linux
`nixos/nix` containers (the lab's suggested second environment). The two
independent builds for the Task 1 / Task 2 proofs are **two fresh
`docker run --rm nixos/nix` containers** — each with its own empty `/nix`
store, so neither can reuse the other's result. Locally that is `aarch64-linux`;
the CI proof (Bonus) is `x86_64-linux` across two runners. Each proof is
internally consistent within its architecture.

## Task 1 — Reproducible Go build via Nix flake

### `flake.nix` (repo root)

```nix
{
  description = "QuickNotes — reproducible builds with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        go = pkgs.go_1_24;                                  # app/go.mod needs >= 1.24
        buildGoModule = pkgs.buildGoModule.override { inherit go; };

        quicknotes = buildGoModule {
          pname = "quicknotes";
          version = "1.0.0";
          src = ./app;
          vendorHash = null;          # zero third-party deps -> nothing to vendor
          CGO_ENABLED = 0;            # static binary
          ldflags = [ "-s" "-w" ];
          doCheck = false;
        };

        seed = pkgs.runCommand "quicknotes-seed" { } ''
          mkdir -p $out; cp ${./app/seed.json} $out/seed.json
        '';

        dockerImage = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:01Z";   # pinned -> deterministic
          copyToRoot = [ quicknotes seed ];
          extraCommands = ''mkdir -p tmp; chmod 1777 tmp'';  # writable /tmp for nonroot
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532";
            Env = [ "ADDR=:8080" "DATA_PATH=/tmp/notes.json" "SEED_PATH=/seed.json" ];
          };
        };
      in {
        packages = { quicknotes = quicknotes; default = quicknotes; docker = dockerImage; };
        devShells.default = pkgs.mkShell { packages = [ go pkgs.gopls pkgs.golangci-lint ]; };
      });
}
```

`flake.lock` is committed (auto-generated), pinning `nixpkgs` and `flake-utils`
to exact revisions.

### It builds and runs

```
$ nix build .#quicknotes
$ ./result/bin/quicknotes & curl -s http://127.0.0.1:8080/health
{"notes":0,"status":"ok"}
```

(`notes:0` — run without `SEED_PATH`; the binary starts and serves `/health`.)

### Two independent builds — identical store hash

Two fresh `nixos/nix` containers, each building from a clean copy:

```
ENV A  QUICKNOTES_HASH=sha256:0c0k0a1g6ykpqswki1k92a50d7rw1rrv47fiw21mxh0ycyj81ylv
ENV B  QUICKNOTES_HASH=sha256:0c0k0a1g6ykpqswki1k92a50d7rw1rrv47fiw21mxh0ycyj81ylv
RESULT: MATCH  (reproducible)
```

### 1.3 Design questions

**a) Why doesn't `go build` produce bit-identical output on two machines from the same Git SHA?**
The compiler embeds machine-specific state. Without `-trimpath` the binary bakes in absolute build paths (the module cache / working dir under `$HOME`), which differ per user/machine. Go also computes a build ID from its inputs, and the toolchain version itself may differ between machines. Archive members and any timestamped generated files add more drift. Same source ≠ same bytes unless you pin the toolchain, strip paths, and control the environment — which is exactly what Nix does (fixed `go_1_24`, sandbox, `-trimpath` from `buildGoModule`).

**b) `vendorHash` is a SHA over what? What if you set it to `null`?**
It is a fixed-output hash over the **entire vendored dependency tree** — every module `buildGoModule` fetches from `go.mod`/`go.sum`, laid out as `vendor/`. It pins the exact bytes of all dependencies so the fetch is reproducible. `vendorHash = null` tells `buildGoModule` there is **nothing to vendor** — valid only when the module has no external dependencies. QuickNotes has zero (`go.mod` has no `require`, no `go.sum`), so `null` is correct. Setting `null` on a module that *does* have deps fails the build.

**c) Why is `flake.lock` the single most important file for reproducibility? What if you delete it before the second build?**
`flake.lock` records the exact git revision (and NAR hash) of every input — `nixpkgs`, `flake-utils` — so every build resolves to the identical package set: same Go, same `stdenv`, same `dockerTools`. `nixpkgs.url = ...nixos-25.05` names a *branch*; the lock turns it into an *exact commit*. Delete it before the second build and Nix re-resolves the inputs to whatever the channel's HEAD is now — a different nixpkgs revision → different compiler/libs → different store hash. Reproducibility breaks immediately.

**d) `buildGoModule` vs `buildGoApplication` — difference, and which for QuickNotes?**
`buildGoModule` vendors all deps in one fixed-output derivation keyed by `vendorHash`. `buildGoApplication` (gomod2nix et al.) builds each dependency as its own Nix derivation from a generated lock, giving per-dependency caching and no `vendorHash`, at the cost of an extra tool + generated file. For QuickNotes I picked **`buildGoModule`**: with zero dependencies there is nothing to vendor (`vendorHash = null`), so `buildGoApplication`'s per-dep granularity buys nothing and only adds an external input.

## Task 2 — Deterministic OCI image

The `docker` output uses `pkgs.dockerTools.buildImage` (see flake above): binary as
exec-form `Entrypoint`, `ExposedPorts` includes `8080/tcp`, nonroot `User 65532:65532`,
built entirely by Nix — no `docker build`. `created` is pinned so the tarball is byte-stable.

### Two independent builds — identical image digest

```
ENV A  IMAGE_SHA256=25d87dc3384e3c599cd69bac5b443418aa14e8063a6c2d9d1ff803e43d8158a2
ENV B  IMAGE_SHA256=25d87dc3384e3c599cd69bac5b443418aa14e8063a6c2d9d1ff803e43d8158a2
RESULT: MATCH
```

The tarball copied out of the container and re-hashed on the host is bit-identical, and the loaded image boots and serves as the nonroot user:

```
$ shasum -a 256 quicknotes-nix.tar.gz
25d87dc3384e3c599cd69bac5b443418aa14e8063a6c2d9d1ff803e43d8158a2  quicknotes-nix.tar.gz
$ docker load -i quicknotes-nix.tar.gz
Loaded image: quicknotes:nix
$ docker run -d --rm -p 8099:8080 quicknotes:nix
$ curl -s http://localhost:8099/health
{"notes":4,"status":"ok"}
```

The image creates a world-writable `/tmp` (via `extraCommands`), so the nonroot
process (UID 65532) can write `DATA_PATH=/tmp/notes.json` on start — without it the
image loads but the process exits with `mkdir /tmp: permission denied`.

### 2.3 Comparison with Lab 6's Dockerfile build

Same Lab 6 Dockerfile, built twice with `--no-cache`:

```
$ docker images --no-trunc qn-lab6
run1  sha256:bab72c97e9c2a54958276c51201a85a0e3751da7a8d3aff20f28ae7350b9b78e   21.9MB
run2  sha256:13e16a8cefb535fa35b02cb5cbffe68881d934af30f0d0767884d493785a1264   21.9MB
```

Two builds of the identical Dockerfile → **two different image IDs** (timestamps
baked into the layers). The Nix image, by contrast, has **one** digest across
every build.

| Image | Build | Digest stable across builds? | Size |
|---|---|---|---|
| `quicknotes:nix` | `nix build .#docker` | **Yes** — `25d87dc3…8158a2` | **20.7MB** |
| `qn-lab6` | `docker build --no-cache` | **No** — `bab72c…` ≠ `13e16a…` | 21.9MB |

The Nix image is also slightly smaller (no distroless CA bundle / passwd layer — just the static binary + seed).

### 2.4 Design questions

**e) What does `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?**
It stamps wall-clock time everywhere: the image config's `created` field is "now", and each `COPY`/`ADD`/`RUN` layer's tar records file mtimes at build time. `RUN` steps can also pull moving targets (latest packages, generated files with timestamps) and base-image tags can drift to new digests. Any of these makes two builds differ. `dockerTools` uses none of it — layers come from content-addressed store paths, timestamps are pinned.

**f) For a security auditor, what can a reproducible image prove that a signed-but-non-reproducible one cannot?**
A signature proves *who* built it and that it hasn't been altered since signing — provenance of one opaque blob. It cannot prove the binary actually corresponds to the published source: a compromised build could inject a backdoor and still be signed. A reproducible image lets *anyone* rebuild from the same source and get the identical digest, proving the artifact is exactly what the public source yields — nothing added. It closes the source→binary trust gap that a signature alone leaves open.

**g) Trade-off of Nix's reproducibility — why is `docker build` still the default for most teams?**
Nix costs a steep learning curve (its language, flakes), forces everything through Nix packaging (anything not in nixpkgs must be packaged), grows a large store, and has a smaller ecosystem. `docker build` is imperative and familiar, works with any base image and shell tooling, and ships value immediately. Most teams weigh velocity and familiarity over bit-for-bit reproducibility, and digest-pinning is "good enough" for them. Nix's rigor pays off specifically where supply-chain verifiability matters.

## Bonus — CI-verified reproducibility

### `.github/workflows/nix-repro.yml`

```yaml
name: nix-repro
on: [push, pull_request]
permissions:
  contents: read
jobs:
  build-a:
    runs-on: ubuntu-latest
    outputs: { digest: "${{ steps.d.outputs.digest }}" }
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: DeterminateSystems/nix-installer-action@3138316df39ed29be04236d7ffc686fa525866aa # v23
      - run: nix build .#docker
      - id: d
        run: echo "digest=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"
  build-b:
    runs-on: ubuntu-latest
    outputs: { digest: "${{ steps.d.outputs.digest }}" }
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: DeterminateSystems/nix-installer-action@3138316df39ed29be04236d7ffc686fa525866aa # v23
      - run: nix build .#docker
      - id: d
        run: echo "digest=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"
  compare:
    needs: [build-a, build-b]
    runs-on: ubuntu-latest
    steps:
      - run: |
          A='${{ needs.build-a.outputs.digest }}'
          B='${{ needs.build-b.outputs.digest }}'
          echo "build-a: $A"; echo "build-b: $B"
          if [ "$A" != "$B" ]; then echo "::error::digests differ"; exit 1; fi
          echo "Reproducible: $A"
```

Two independent runners (`build-a`, `build-b`) build `.#docker`, publish the
digest as a job output; `compare` fails if they differ. The Nix installer is
pinned by 40-char SHA (per the Lab 3 rule), as is `actions/checkout`.

### Green and red runs

| Run | Result | URL |
|---|---|---|
| Baseline | ✅ success | https://github.com/Nik-ari-ai/DevOps-Intro/actions/runs/35579135930 |
| Deliberately broken | ❌ failure | https://github.com/Nik-ari-ai/DevOps-Intro/actions/runs/35579398612 |
| Fixed again | ✅ success | https://github.com/Nik-ari-ai/DevOps-Intro/actions/runs/35579626213 |

For the red run, `build-a` (only) ran `sed -i 's/00:00:01Z/00:00:02Z/' flake.nix`
before building, shifting the pinned image `created`. `build-a` and `build-b`
both built fine; `compare` caught the digest mismatch and failed the workflow.
Removing that step restored green.

### B.4 Design questions

**h) "Reproducible on my laptop" vs "reproducible in CI" — why is the CI proof load-bearing for an auditor?**
On one laptop, both builds share the machine: the same warm `/nix` store, env, user, and time window. Hidden local state (a cached result, a dirty store, an uncommitted file, an ambient env var) can make two builds match by accident, and nobody else can see it. CI runs on fresh, ephemeral, publicly-logged runners with no shared local state, and the match is produced by a third party from the committed source alone — with an auditable log and URL. That is independently verifiable evidence, not a personal claim.

**i) Why two parallel jobs instead of one job that runs `nix build` twice?**
Two builds in one job share the runner: the same `/nix` store (the second build just hits the cache and returns the first result — a tautological "match"), the same filesystem, env, and moment in time. It can't detect nondeterminism arising from machine/store/env differences. Two parallel jobs are two cold, independent runners — a real different-environment test. A single-job double-build could miss store-caching masking real nondeterminism, env leakage, path/user dependence, and time-dependent divergence.

**j) Where would the timestamp normally leak into your Nix flake, and how does `dockerTools.buildImage` handle it?**
In an OCI image, timestamps live in the image config's `created` field and in the mtimes of files inside each layer tar; by default both are wall-clock. `dockerTools.buildImage` avoids wall-clock entirely: it sets `created` to a fixed value (default `1970-01-01T00:00:01Z`, pinned explicitly here) and normalizes file mtimes in the layer tars to a constant, so the tarball is byte-stable. That is also why an ambient `SOURCE_DATE_EPOCH` did nothing in the red demo — the build is sandboxed and the timestamp is pinned in the derivation, so forcing a divergence required editing the pinned `created` itself.
