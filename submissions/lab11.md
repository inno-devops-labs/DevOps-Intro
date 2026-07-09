# Lab 11

Files: [`flake.nix`](../flake.nix), [`flake.lock`](../flake.lock),
[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml).

---

## Task 1 - Reproducible Go build via Nix flake

`flake.nix` pins `nixpkgs` to nixos-25.05 (via `flake.lock`), exposes
`packages.quicknotes` (+ `default`) built with `buildGoModule` from `./app`,
with `CGO_ENABLED = 0` (static), `vendorHash = null` (QuickNotes has zero
third-party deps), and `ldflags = ["-s" "-w"]`. A `devShell` provides `go`,
`gopls`, `golangci-lint`.

> nixos-24.11 ships Go 1.23, but `go.mod` requires `go 1.24` and Nix pins
> `GOTOOLCHAIN=local` (no network toolchain download) - so I bumped the channel to
> nixos-25.05, which ships Go 1.24.

### Build + run

```
$ nix build .#quicknotes          # inside nixos/nix, nixpkgs pinned via flake.lock
$ ls -l result/bin/quicknotes
-r-xr-xr-x 1 root root 5863824 Jan  1  1970 quicknotes   # note: epoch mtime (deterministic)
$ DATA_PATH=/tmp/notes.json SEED_PATH=app/seed.json ./result/bin/quicknotes &
   quicknotes listening on :8080 (notes loaded: 4)
$ curl -s localhost:8080/health
{"notes":4,"status":"ok"}
```

### Reproducibility - two independent builds, identical store hash

Built in two independent environments (env A = a persisted `/nix` volume; env B =
a fresh `docker run --rm` with an empty store that re-downloads everything), each
`nix-store --query --hash $(readlink result)`:
```
env A:  sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
env B:  sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
        → IDENTICAL ✅
```

### 1.3 Design questions

a) Why doesn't `go build` produce bit-identical outputs on two machines from the
same Git SHA? Without `-trimpath` the binary embeds absolute build paths
(`/home/you/...`), and Go embeds a build ID derived from those inputs; VCS
stamping (`-buildvcs`) bakes in git state/time; and a different Go compiler
version emits different code. Same source ≠ same bytes unless you pin the
toolchain and strip paths/timestamps - which is exactly what Nix + `-trimpath` +
`-s -w` do.

b) `vendorHash` is a SHA over what? Over the entire vendored dependency
tree - the fixed-output hash of what `go mod vendor` produces (all module
sources, normalized). It makes the dependency fetch hermetic: the build only
succeeds if the deps hash to exactly that value. `vendorHash = null` tells
`buildGoModule` there are no deps to vendor - correct for QuickNotes (zero
deps); for a module with dependencies, `null` fails the build because it skips
fetching them.

c) Why is `flake.lock` the single most important file for reproducibility? It
pins `nixpkgs` to an exact git revision, which fixes the entire build graph -
the Go compiler, stdlib, build tools, `dockerTools` - to identical bytes across
machines and time. Delete it before the second build and Nix re-resolves
`nixos-25.05` to whatever the branch tip is now (a different revision → maybe a
different Go point release) → the output hash can change. The lock is what makes
"same inputs" literally true.

d) `buildGoModule` vs `buildGoApplication`? `buildGoModule` (in nixpkgs)
vendors all deps through one fixed-output derivation keyed by `vendorHash` - simple,
self-contained, no extra tooling. `buildGoApplication` (from `gomod2nix`) builds
each dependency as its own Nix derivation from a generated `gomod2nix.toml` - finer
caching, no single `vendorHash`, but adds a codegen step and a non-nixpkgs input.
For QuickNotes (zero deps, stay in nixpkgs, minimal moving parts) `buildGoModule`
with `vendorHash = null` is the right pick.

---

## Task 2 - Deterministic OCI image

`flake.nix` also exposes `packages.docker` via `pkgs.dockerTools.buildImage` -
built entirely by Nix, no Docker daemon. It sets the QuickNotes binary as the
exec-form `Entrypoint`, `ExposedPorts` `8080/tcp`, and runs as `65534:65534`
(nonroot). `dockerTools` pins all layer mtimes to the epoch, so the tarball is
byte-deterministic.

### Two independent builds → identical SHA-256

```
$ nix build .#docker && sha256sum result
env A:  c27cf6d02f9a33f219d6176cb47c1c3b70a0d0665592b31346591577658c6478
env B:  c27cf6d02f9a33f219d6176cb47c1c3b70a0d0665592b31346591577658c6478
        → IDENTICAL ✅
```
`docker load < result` → `quicknotes-nix:latest`. The image is intentionally
minimal (no `/tmp`), so it's run with a writable scratch mount -
`docker run --tmpfs /tmp:rw,mode=1777 ...` (the same read-only-rootfs + tmpfs
pattern as Lab 6) → `/health` → `{"notes":0,"status":"ok"}`.

### Contrast: Lab 6 `docker build --no-cache` twice → digests differ

```
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6
run1  sha256:1f7a2de2d8fbce750eb1f706f8c17b3dd6db6455adef3d57bf7a7cdac4859131
run2  sha256:f70c38c935beb8a22606582fd6f1cd2363131317ee8fd0a6a6612c5e4b794008
        → DIFFER (layer/image timestamps) - non-reproducible
```

### Size comparison

| Artifact | Size |
|----------|------|
| Nix `dockerTools` image | 21.4 MB loaded (3.0 MB tar) |
| Lab 6 `docker build` image | 22.7 MB |
| static Go binary | 5.6 MB |

### 2.4 Design questions

e) What does `docker build` do that's non-deterministic? It stamps a
creation timestamp on the image and records layer mtimes at build time; `RUN`
steps execute at build time so their filesystem output carries fresh timestamps
(and can fetch changing content, e.g. `apt`); tar ordering/metadata vary. So the
same Dockerfile + SHA yields different layer digests. `dockerTools.buildImage`
avoids all of this: epoch mtimes, no "now" created date, and inputs are already
deterministic Nix store paths.

f) What can a reproducible image prove that a signed-but-non-reproducible one
can't? A reproducible image lets an auditor rebuild from source and get the
identical digest - proving the published artifact corresponds exactly to this
source (no tampering slipped in between source and registry). A signature only
proves who published it and that it wasn't altered after signing - a
compromised build pipeline can sign a backdoored image. Reproducibility closes the
source→artifact gap; signing closes the artifact→publisher gap.

g) The trade-off of Nix's reproducibility? A steep learning curve and a whole
new language/model; every build step must be pure (no ad-hoc `RUN curl | sh`);
onboarding and ecosystem friction (not everything is packaged); a large Nix store.
`docker build` stays the default because it's simple, ubiquitous, matches the
imperative mental model devs already have, and is "good enough" - most teams don't
*require* bit-for-bit determinism. Nix earns its cost when supply-chain integrity
is a hard requirement.

---

## Bonus - CI-verified reproducibility

[`nix-repro.yml`](../.github/workflows/nix-repro.yml): on push/PR, two parallel
jobs (`build-a`, `build-b`) on separate fresh runners each `nix build .#docker`
and export `sha256sum result`; a third `compare` job fails the workflow unless
the two digests match. The Nix-installer action is SHA-pinned (`v9`).

> The green run shows two equal digests; a red run is produced by, e.g., injecting
> a different `SOURCE_DATE_EPOCH` into one job so its layer mtimes differ → digests
> diverge → `compare` exits non-zero.

### B.4 Design questions

h) "Reproducible on my laptop" vs "in CI". Your laptop carries hidden state - a
warm Nix store, env vars, installed tools - so two local builds can match merely
because they *share cached artifacts*, not because the build is deterministic. CI
runners are fresh and isolated; identical digests there prove reproducibility
from clean inputs, which is what lets an auditor independently rebuild and verify.

i) Why two parallel jobs, not one job building twice? Two parallel jobs run on
separate runners - genuinely independent (no shared `/nix` store or
filesystem). One job that builds twice shares the same store, so the second build
just returns the cached first result - identical by construction, testing
nothing. A single-job comparison would miss machine- or cache-masked nondeterminism.

j) `SOURCE_DATE_EPOCH` - where would the timestamp leak in, and how does
`dockerTools` handle it? In an image build the timestamp normally leaks via the
image `created` date and the layer file mtimes in the tarball (plus any tool
that stamps "now"). `dockerTools.buildImage` neutralizes it: it sets all mtimes to
the epoch (1970-01-01) and doesn't record a live "created" date, so the tarball is
byte-identical no matter when it's built - `SOURCE_DATE_EPOCH` is effectively
baked to 0.
