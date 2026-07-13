# Lab 11 — Reproducible Builds of QuickNotes with Nix

Branch: `feature/lab11` · Flake: [`flake.nix`](../flake.nix) · Lock: [`flake.lock`](../flake.lock) · CI gate: [`nix-repro.yml`](../.github/workflows/nix-repro.yml)

Environments used for the two-build proofs: independent, fresh `nixos/nix` Docker containers (`--rm`, empty store, source fetched from GitHub at pinned commit `67a4cc390cd215072873d70407d91826505bed00`), both `aarch64-linux`. CI proofs run on `x86_64-linux` GitHub runners — digests there differ from the local ones (different architecture), but each comparison pair is same-arch, which is what reproducibility claims.

---

## Task 1 — Reproducible Go build via Nix flake

### flake.nix

```nix
{
  description = "QuickNotes — reproducible Go build + deterministic OCI image (Lab 11)";

  inputs = {
    # Channel pin; flake.lock freezes the exact nixpkgs revision (and thereby
    # the exact Go toolchain), so every clone builds with identical inputs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      # Binary + devShell build everywhere; the OCI image output is Linux-only
      # (a darwin-arch image tarball would be useless to Docker).
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # QuickNotes is stdlib-only: go.mod has zero require lines and no
            # go.sum exists, so there is nothing to vendor — null skips the
            # vendor derivation entirely. The moment a third-party dependency
            # appears, replace null with the `got: sha256-…` value that the
            # first failing build prints.
            vendorHash = null;

            env.CGO_ENABLED = "0";   # fully static binary, no libc reference
            ldflags = [ "-s" "-w" ]; # strip symbol table + DWARF (Lab 6 carry-over)
            # buildGoModule already passes -trimpath, removing absolute
            # build-directory paths from the binary.
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;
        }
        // nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            # Fixed timestamp → deterministic image config JSON. dockerTools
            # also normalizes every file mtime in the layer tar to this epoch,
            # which is exactly what SOURCE_DATE_EPOCH does for other tools.
            created = "1970-01-01T00:00:01Z";

            copyToRoot = pkgs.buildEnv {
              name = "quicknotes-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };

            # Runs while packing the image root — no Docker daemon involved.
            # /data must be writable by uid 65532; buildImage packs files as
            # root-owned without a VM, so a 0777 dir replaces Lab 6's chown.
            extraCommands = ''
              cp ${./app/seed.json} seed.json
              mkdir -p data
              chmod 0777 data
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ]; # exec form
              ExposedPorts = { "8080/tcp" = { }; };
              User = "65532:65532";               # distroless "nonroot" uid:gid
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ go gopls golangci-lint ];
        };
      });
    };
}
```

Choices, mapped to the requirements:

1. **nixpkgs pinned** to `github:NixOS/nixpkgs/nixos-25.11` in `inputs:`; [`flake.lock`](../flake.lock) freezes it to revision `b6018f87da91d19d0ab4cf979885689b469cdd41` (2026-06-30), which transitively pins the Go toolchain to **go 1.25.10** (satisfies `go.mod`'s `go 1.24` floor).
2. `packages.<system>.quicknotes` (and `default`) builds the `app/` sources.
3. **`buildGoModule`** — rationale in design answer (d).
4. `env.CGO_ENABLED = "0"` → static binary; the build log confirms it: `patchelf: cannot find section '.dynamic'. The input file is most likely statically linked`.
5. **`vendorHash = null`** — QuickNotes is stdlib-only: `go.mod` contains zero `require` lines and no `go.sum` exists, so there is no vendor tree to hash. `null` is the nixpkgs-blessed pin for dependency-free modules; the "paste the `got:` hash from the first failed build" dance only happens once a third-party dependency appears. (Design answer (b) explains what `null` does.)
6. `ldflags = [ "-s" "-w" ]` — carried from Lab 6; `buildGoModule` adds `-trimpath` on its own.
7. `devShells.<system>.default` ships `go`, `gopls`, `golangci-lint` — verified via `nix develop` ([artifact](lab11/task1-devshell.txt)):

```text
go version go1.25.10 linux/arm64
golang.org/x/tools/gopls v0.20.0
golangci-lint has version 2.6.2 built with go1.25.10 from v2.6.2 on 1970-01-01T00:00:00Z
```

### Build log excerpt

Full log: [task1-build-envA.txt](lab11/task1-build-envA.txt)

```text
building '/nix/store/3ymwh11sp830gbqr7vliqmi7pj3nswmq-quicknotes-0.1.0.drv'...
quicknotes> unpacking source archive /nix/store/n4csrdhxqcazy61jsjsb4s0pqa32hbzl-app
quicknotes> Running phase: buildPhase
quicknotes> Building subPackage .
quicknotes> Running phase: checkPhase
quicknotes> ok          quicknotes      0.003s
quicknotes> Running phase: installPhase
quicknotes> stripping (with command strip and flags -S -p) in  /nix/store/m50l6ri8y66ckm91iwnqyppnxi2wklkl-quicknotes-0.1.0/bin
```

(the unit tests from Labs 1–9 run inside the sandboxed `checkPhase` — reproducibility proof and test gate in one derivation)

### Two-environment store-hash proof

Artifacts: [task1-hash-envA.txt](lab11/task1-hash-envA.txt) / [task1-hash-envB.txt](lab11/task1-hash-envB.txt)

```text
# environment A (fresh container, empty store)
$ nix-store --query --hash $(readlink result)
sha256:08jfl5c3ahdr34b8lnybyvdjsahcsv59gkh9030a7frsa9z5r94i

# environment B (second fresh container, empty store)
$ nix-store --query --hash $(readlink result)
sha256:08jfl5c3ahdr34b8lnybyvdjsahcsv59gkh9030a7frsa9z5r94i

$ diff task1-hash-envA.txt task1-hash-envB.txt && echo IDENTICAL
IDENTICAL
```

(the same hash was in fact obtained in **three** fresh containers during the session)

### Runs and serves /health

[task1-run-envA.txt](lab11/task1-run-envA.txt) — `./result/bin/quicknotes &`, then the binary's own healthcheck probe and curl:

```text
2026/07/13 13:10:35 quicknotes listening on :8080 (notes loaded: 0)
HEALTHCHECK-OK
{"notes":0,"status":"ok"}
```

### Design questions

**a) Why doesn't `go build` produce bit-identical outputs on two machines, even from the same Git SHA?**
Because the toolchain embeds machine- and moment-specific data into the binary: absolute build paths (unless `-trimpath`), the Go **build ID** (derived from the action graph — it changes with toolchain version, GOROOT paths, cache state), VCS stamping (`-buildvcs` embeds commit/dirty state), and env-dependent settings (`CGO_ENABLED`, `GOOS/GOARCH`, `GOFLAGS`) that silently differ between machines. Two machines also rarely run byte-identical toolchains: go 1.24.1 vs 1.24.13 compile different code. And without a lockfile for the *build environment* itself, "same Git SHA" pins your source but nothing else. Nix closes every one of those holes: the compiler, flags, and environment are all inputs to the derivation hash, the sandbox hides the host, and `-trimpath` plus disabled VCS stamping remove path/metadata leaks.

**b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?**
It is an SRI SHA-256 over the **NAR serialization of the vendored dependency tree** — the output of the internal `goModules` fixed-output derivation, which runs `go mod download`/`go mod vendor` for everything in `go.mod`/`go.sum`. Fixed-output derivations are the only ones allowed network access, and the price is declaring the output hash up front — that's why the first build "fails" and hands you the `got:` value. `vendorHash = null` tells `buildGoModule` to **skip the vendor derivation entirely**: no module downloads happen at all. For a module with dependencies that's a broken build (the sandbox has no network), but for stdlib-only QuickNotes it is exactly right — there is nothing to fetch, so there is nothing to hash.

**c) Why is `flake.lock` the single most important file for reproducibility? What happens if you delete it before the second build?**
`inputs.nixpkgs.url = "…/nixos-25.11"` names a *moving branch*; `flake.lock` resolves it to one immutable commit + content hash (`b6018f87…`, narHash-pinned). That single revision determines the entire build environment: the Go compiler, stdenv, coreutils, every flag — the whole dependency graph that becomes the derivation hash. Delete it before the second build and Nix re-resolves the branch to whatever its tip is *that day*: a newer nixpkgs likely means a different Go toolchain, hence a different binary, hence different store hashes — the reproducibility claim silently evaporates while the flake "still works". That's why `flake.nix` and `flake.lock` are committed together (the upstream `.gitignore` even says so).

**d) `buildGoModule` vs `buildGoApplication` — which one for QuickNotes and why?**
`buildGoModule` lives in nixpkgs itself and models *all* dependencies as one fixed-output vendor derivation pinned by a single `vendorHash`. `buildGoApplication` (gomod2nix) generates a per-dependency Nix expression (`gomod2nix.toml`), so each module becomes its own cached derivation — better granular caching and no whole-hash bump when one dep changes, at the cost of an extra external tool and a generated lockfile to keep in sync. For QuickNotes the choice is trivial: **zero dependencies** means gomod2nix's whole value proposition buys nothing, while `buildGoModule` needs no extra tooling and collapses to `vendorHash = null`. `buildGoModule` it is.

---

## Task 2 — Deterministic OCI image

### Flake output

See the `docker = pkgs.dockerTools.buildImage { … }` block in the flake above. Requirements mapping: built by **`pkgs.dockerTools.buildImage`** — no Docker daemon involved (built inside plain Nix containers and on CI runners before any `docker` command); `Entrypoint = [ "/bin/quicknotes" ]` (exec form); `ExposedPorts."8080/tcp"`; runs as `User = "65532:65532"` (the distroless `nonroot` uid carried from Lab 6 — `buildImage` packs files without root, so a `0777 /data` replaces the Dockerfile's `chown`); `created` fixed at epoch so the config JSON is deterministic.

### Two-environment digest proof

Artifacts: [task2-digest-envA.txt](lab11/task2-digest-envA.txt) / [task2-digest-envB.txt](lab11/task2-digest-envB.txt)

```text
# environment A                                # environment B
$ sha256sum result                             $ sha256sum result
1289d8a7e0b15e549f6bfa46dfe4d72efbf5c9bc322d26508946041ea6e21d0f  result   (both)

$ diff task2-digest-envA.txt task2-digest-envB.txt && echo IDENTICAL
IDENTICAL
```

### Loadable + runnable via Docker

```text
$ docker load -i quicknotes-nix-image.tar
Loaded image: quicknotes:nix
$ docker run -d --rm --name qn-nix -p 8081:8080 quicknotes:nix
$ curl -s localhost:8081/health
{"notes":4,"status":"ok"}
```

(4 notes = seeded from `/seed.json`, i.e. the image's env wiring and the writable `/data` both work under the nonroot uid; host port 8081 because 8080 is held by the Lab 8 monitoring stack)

### Lab 6 contrast — `docker build --no-cache` twice

Artifact: [task2-lab6-digests.txt](lab11/task2-lab6-digests.txt)

```text
$ docker images --no-trunc qn-lab6
REPOSITORY   TAG    IMAGE ID                                                                  CREATED          SIZE
qn-lab6      run2   sha256:be943c5a753b05eb63fc42be5ba9f855ca652434edb7e8cd1b815dd66fadf45f   2 seconds ago    15.1MB
qn-lab6      run1   sha256:ad1ec1c6b00e9086792d1132b51410b22e18cbe90b5a11c379b1c4cbdd4c4428   28 seconds ago   15.1MB
```

Two `--no-cache` builds of the **same Dockerfile at the same Git SHA, 26 seconds apart** → different image IDs (the ID is the SHA-256 of the config JSON, which embeds per-layer creation timestamps; BuildKit also regenerates the attestation manifest). The two Nix tarballs, meanwhile, are byte-identical.

### Size comparison

| Image | IMAGE ID | CREATED (as shown by Docker) | Size |
|-------|----------|------------------------------|-----:|
| Nix `quicknotes:nix` | `3c69677ac02b` — same in any rebuild | **"56 years ago"** (pinned epoch `created`) | 21.6MB |
| Lab 6 `qn-lab6` (distroless multi-stage) | `ad1ec1c6…` / `be943c5a…` — differs per rebuild | seconds ago (wall clock) | 15.1MB |

The Nix image is ~6MB larger: it ships the binary in a single uncompressed layer under `/nix/store` plus a `/bin` symlink farm, with none of distroless's size tuning. The Lab 6 image is smaller but non-deterministic; the "56 years ago" timestamp is the visible cost-free proof that no wall clock entered the Nix build.

### Design questions

**e) What does `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?**
It stamps *wall-clock time* everywhere: each layer's tar entries carry real file mtimes, and the image config records `created` plus a per-instruction `history` timestamp — so two runs seconds apart already hash differently (exactly what our `run1`/`run2` show). Beyond time: `FROM golang:1.26-alpine` is a moving tag (the base can change between pulls), `RUN` steps execute arbitrary commands with network access (`go mod download`, `apk add`) whose results depend on the state of the outside world at that moment, and BuildKit injects freshly-generated attestation/provenance manifests. `dockerTools.buildImage` eliminates all of it: contents come from Nix store paths (already reproducible), every mtime is normalized to the fixed `created` epoch, and no network or clock is consulted while packing.

**f) For a security auditor, what does a reproducible image prove that a signed-but-non-reproducible image cannot?**
A signature only proves *who* published the artifact — it says nothing about whether the artifact actually corresponds to the source it claims to be built from. If the build host or pipeline was compromised (SolarWinds-style), the attacker's backdoored binary gets signed just as happily. A reproducible image makes the source→artifact link **independently verifiable**: any auditor can rebuild from the audited Git SHA and compare digests; a single injected byte changes the hash. Signing moves trust to a key; reproducibility removes the need to trust the build machine at all — you verify instead of trust. The two compose: sign the artifact *and* let anyone reproduce it.

**g) What's the trade-off? Why is `docker build` still the default?**
Nix's price is a steep on-ramp: a new language and mental model, hashes to babysit (`vendorHash` bumps on every dep change), a multi-gigabyte `/nix/store`, slower cold builds (~143MiB of toolchain fetched into each fresh environment here), and friction whenever software assumes FHS paths or network at build time. Dockerfiles are imperative shell every engineer already knows, integrate with every CI/registry out of the box, and their layer cache is "good enough" fast. Most teams' threat model doesn't *require* bit-identical builds — "same tag, passes tests" suffices — so they rationally spend their complexity budget elsewhere. Reproducibility pays off when the artifact itself is the trust boundary: supply-chain-sensitive software, auditable releases, long-lived security guarantees.

---

## Bonus — CI-verified reproducibility

### Workflow

[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml) — triggers on every push + PR; `build-a` and `build-b` run in parallel on fresh `ubuntu-24.04` runners, each installs Nix via the Determinate installer action, runs `nix build .#docker`, and exports `sha256sum result` as a job output; `compare` fails the workflow unless both digests are non-empty and equal. Both actions pinned by 40-char SHA (Lab 3 rule): `actions/checkout@93cb6efe…` (v5.0.1), `DeterminateSystems/nix-installer-action@ef8a1480…` (v22).

### Green run (digests match)

<https://github.com/Dnau15/DevOps-Intro/actions/runs/29254368711> — log: [bonus-green-log.txt](lab11/bonus-green-log.txt)

```text
build-a  image tarball sha256: 5978db8817d53902c87863a6fb550549cd0822f3e1d5bd66fe160e29cf7652bd
build-b  image tarball sha256: 5978db8817d53902c87863a6fb550549cd0822f3e1d5bd66fe160e29cf7652bd
compare  reproducible: both runners produced 5978db8817d53902c87863a6fb550549cd0822f3e1d5bd66fe160e29cf7652bd
```

(An earlier run of the same commit, [29253774848](https://github.com/Dnau15/DevOps-Intro/actions/runs/29253774848), failed in `build-b`'s **Set up job** with GitHub's "Failed to resolve action download info / Service Unavailable" — runner-infrastructure flake, not a digest mismatch; retriggered with an empty commit.)

### Red run (deliberate divergence caught)

Commit `f4006ac` added a step to **job A only** that sed-patched the image's `created` timestamp in `flake.nix` before building — deliberately reopening the timestamp channel that `dockerTools` pins down (see answer j). Note the original lab hint of exporting a different `SOURCE_DATE_EPOCH` in one job would *not* have worked: runner env vars never reach the Nix build sandbox, so the input had to actually change.

<https://github.com/Dnau15/DevOps-Intro/actions/runs/29254731141> — log: [bonus-red-log.txt](lab11/bonus-red-log.txt)

```text
build-a  image tarball sha256: 2e3ddd95d8dd9d9b5595bb8576434f982e7ccf97784361cae38a9940e93e7687
build-b  image tarball sha256: 5978db8817d53902c87863a6fb550549cd0822f3e1d5bd66fe160e29cf7652bd
compare  ##[error]build is NOT reproducible — digests differ
```

Reverted in `b8d7c8f` → green again: <https://github.com/Dnau15/DevOps-Intro/actions/runs/29254988676>

### Design questions

**h) "Reproducible on my laptop" vs "reproducible in CI" — why is the CI proof load-bearing?**
A laptop claim is a screenshot from an environment nobody else can inspect: warm caches and leftover store paths can mask impurity, both "builds" may share machine state, and the evidence is neither independent nor durable. CI gives an auditor what evidence actually requires: **fresh, disposable environments** whose full provisioning is declared in versioned YAML, **publicly attributable logs** tied to an exact commit, and **continuous re-proof on every push** — reproducibility becomes an enforced invariant that a regression breaks loudly (our red run is that mechanism firing), not a one-off anecdote about a golden machine.

**i) Why two parallel jobs instead of one job running `nix build` twice?**
Because the second `nix build` in the same job is a **no-op**: the store path already exists in the local Nix store, so Nix just returns it — you would compare a file with itself and "prove" reproducibility of the cache, tautologically. Even forcing a rebuild (`--rebuild`, store gc) still leaves both builds on one machine, sharing kernel, CPU, filesystem state, and any local impurity — precisely the variables independence is supposed to rule out. Two parallel jobs are two runners that have never seen each other's state; agreement between them is evidence, not an artifact of shared cache.

**j) Where would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?**
Two channels: (1) the **layer tarball** — every file entry carries an mtime, which for freshly created files is "now"; (2) the **image config JSON** — the `created` field and per-layer `history` timestamps, which are hashed into the image ID. `dockerTools.buildImage` closes both by construction: it sets `created` to the value pinned in the flake (`1970-01-01T00:00:01Z` here — hence Docker showing the image as created "56 years ago") and normalizes all file mtimes in the layer tar to that same epoch — the effect `SOURCE_DATE_EPOCH=0` has in other build tools, but enforced by the packer rather than requested via the environment. The Go binary itself contributes no timestamp (Go doesn't embed build time; `-trimpath` and the sandbox strip path/VCS noise). Our red run weaponized exactly this channel by patching `created` in one job — a one-line, one-field change flipped the whole-image digest.

---

## Artifacts

| File | What it proves |
|------|----------------|
| [`lab11/task1-build-envA.txt`](lab11/task1-build-envA.txt) | Task 1 build log (fresh store → local build) |
| [`lab11/task1-hash-envA.txt`](lab11/task1-hash-envA.txt) / [`task1-hash-envB.txt`](lab11/task1-hash-envB.txt) | identical store hashes across environments |
| [`lab11/task1-run-envA.txt`](lab11/task1-run-envA.txt) | binary runs, self-healthcheck + `/health` OK |
| [`lab11/task1-devshell.txt`](lab11/task1-devshell.txt) | devShell provides go/gopls/golangci-lint |
| [`lab11/task2-build-envA.txt`](lab11/task2-build-envA.txt) | image built by Nix alone (no Docker) |
| [`lab11/task2-digest-envA.txt`](lab11/task2-digest-envA.txt) / [`task2-digest-envB.txt`](lab11/task2-digest-envB.txt) | identical image digests across environments |
| [`lab11/task2-nix-run.txt`](lab11/task2-nix-run.txt) | Nix image loads into Docker and serves `/health` |
| [`lab11/task2-nix-image-size.txt`](lab11/task2-nix-image-size.txt) | Nix image size + epoch timestamp |
| [`lab11/task2-lab6-digests.txt`](lab11/task2-lab6-digests.txt) | Lab 6 `--no-cache` double build → differing IDs |
| [`lab11/bonus-green-log.txt`](lab11/bonus-green-log.txt) | CI: two runners, equal digests |
| [`lab11/bonus-red-log.txt`](lab11/bonus-red-log.txt) | CI: divergence detected, workflow failed |
