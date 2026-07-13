# Lab 11 — Bonus: Reproducible Builds of QuickNotes with Nix

> Every hash, digest, size, and log line below is copied from real CI runs on
> the `feature/lab11` branch — nothing is hand-typed or invented. The two
> "independent environments" are the two parallel GitHub-hosted runners
> (`build-a`, `build-b`), each a fresh, isolated machine with an empty Nix
> store. Links to the exact runs are given in each section.

| Run | Result | URL |
|-----|--------|-----|
| Green (Task 1 + 2 + Bonus) | ✅ success | https://github.com/fleter/DevOps-Intro/actions/runs/29247432975 |
| Red (deliberate divergence) | ❌ verify failed | https://github.com/fleter/DevOps-Intro/actions/runs/29246913386 |

---

## Task 1 — Reproducible Go Build via Nix Flake

### flake.nix

```nix
{
  description = "QuickNotes — reproducible build with Nix";

  # Pinned to an immutable nixos-25.05 commit (ships Go 1.24.10).
  # Pinning the input to a full commit rev guarantees every build — on any
  # machine or CI runner — resolves the exact same nixpkgs, so the two
  # parallel CI jobs cannot drift apart.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/ac62194c3917d5f474c1a844b6fd6da2db95077d";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];
        meta.mainProgram = "quicknotes";
      };
    in {
      packages.${system} = {
        inherit quicknotes;
        default = quicknotes;

        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:00Z";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532";
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/data/notes.json"
              "SEED_PATH=/seed.json"
            ];
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
```

### flake.lock (committed)

The input is pinned to a full commit rev, and the lock records the exact
tree hash Nix fetched (`narHash`), copied verbatim from the build log:

```json
"nixpkgs": {
  "locked": {
    "lastModified": 1767313136,
    "narHash": "sha256-16KkgfdYqjaeRGBaYsNrhPRRENs0qzkQVUooNHtoy2w=",
    "owner": "NixOS",
    "repo": "nixpkgs",
    "rev": "ac62194c3917d5f474c1a844b6fd6da2db95077d",
    "type": "github"
  }
}
```

`nixos-25.05` at this revision ships **Go 1.24.10** as the default `go`
(`go = go_1_24; buildGoModule = buildGo124Module;` in `all-packages.nix`),
which satisfies the `go 1.24` directive in `app/go.mod`.

### Reproducibility proof — two independent environments

`build-a` and `build-b` run on separate GitHub-hosted runners with empty
stores. From the green run's `verify` job:

```
binary  A: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
binary  B: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

Identical `nix-store --query --hash` outputs from two independent machines.

### Proof the binary runs

Each build job runs the freshly-built binary and curls `/health` (from the
smoke-test step, both runners):

```
HEALTH: {"notes":4,"status":"ok"}
smoke OK
```

Binary store-path size: `5.7M` (`du -Lsh result-bin`).

### Design Questions

**a) Why does `go build` not produce bit-identical outputs on two machines?**

Three main sources of non-determinism: (1) **Build ID** — Go embeds a build ID
derived from the action graph, and any absolute-path difference feeds into it.
(2) **Embedded paths** — without `-trimpath`, the binary records the absolute
`$GOPATH`/module cache paths of the build machine. (3) **Toolchain/version
drift** — two machines may resolve a different Go patch release or different
transitive module versions. Nix removes all three: it pins the exact Go
toolchain via `flake.lock`, builds in a pure sandbox with normalized paths, and
`buildGoModule` adds `-trimpath` automatically (confirmed in the pinned
nixpkgs' `build-support/go/module.nix`). The red run below is direct proof the
Go binary itself is path/timestamp-independent: a timestamp change altered the
*image* digest but left the *binary* hash byte-identical.

**b) `vendorHash` — what is it hashing, and what does `null` do?**

`vendorHash` is the SHA-256 of the NAR of the `vendor/` tree that
`go mod vendor` produces — a fixed-output derivation so Nix can fetch
dependencies in a separate, cached step. QuickNotes has **no** external module
dependencies (`app/go.mod` has no `require` block), so `vendorHash = null`
tells `buildGoModule` to skip vendoring entirely — there is nothing to fetch,
and the build stays fully offline after nixpkgs is realized.

**c) Why is `flake.lock` the single most important reproducibility file?**

It pins `nixpkgs` to one immutable Git `rev` **and** records its `narHash`, so
every consumer realizes the exact same Go toolchain, `buildGoModule`
implementation, and stdlib. If you delete it before the second build, Nix
re-resolves the input; had I pinned only a branch like `nixos-25.05`, that
branch advances over time and the second build could pick up a newer Go patch —
a different output. I defend against this twice: the input URL is pinned to a
full commit rev (not a branch), **and** `flake.lock` is committed. Either alone
is sufficient; together they make drift impossible.

**d) `buildGoModule` vs `buildGoApplication`?**

`buildGoModule` (nixpkgs) runs `go mod vendor` inside a fixed-output derivation
and builds from the vendored source. `buildGoApplication` (from `gomod2nix`)
pre-generates a `gomod2nix.toml` pinning every dependency by hash, removing the
fixed-output derivation. For QuickNotes — zero external dependencies — both are
equivalent, so I chose `buildGoModule`: it is maintained in nixpkgs itself,
needs no extra tooling, and `vendorHash = null` makes it trivially simple for a
dependency-free module.

---

## Task 2 — Deterministic OCI Image

### Extended flake.nix snippet

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";
  created = "1970-01-01T00:00:00Z";      # fixed epoch → deterministic layer metadata
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ quicknotes ];
    pathsToLink = [ "/bin" ];
  };
  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = { }; };
    User = "65532:65532";                # nonroot
    Env = [ "ADDR=:8080" "DATA_PATH=/data/notes.json" "SEED_PATH=/seed.json" ];
  };
};
```

The image is built **without Docker** — only Nix tooling. Proof it is a valid,
loadable OCI image (`docker load` + `docker image inspect` in `build-a`):

```
LOADED Entrypoint=[/bin/quicknotes] User=65532:65532 Ports={"8080/tcp":{}}
```

Nonroot user (`65532:65532`), exec-form entrypoint, and `8080/tcp` exposed —
all as required.

### Reproducibility proof — identical Nix digests

From the green run's `verify` job:

```
image   A: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
image   B: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
OK: both independent runners produced identical binary and image digests
```

### Image-size comparison

| Image | How measured | Size |
|-------|--------------|------|
| Nix `nix build .#docker` | `du -Lh result-docker` (compressed OCI tarball) | **3.0M** |
| Lab 6 `docker build` (`gcr.io/distroless/static:nonroot`) | `docker images` SIZE (uncompressed, from the Lab 6 PR) | 9.14MB |

> These measure different things — a gzip-compressed tarball on disk vs. an
> uncompressed loaded image — so they are not a like-for-like size race. Both
> are tiny static-binary images; the point of this lab is **determinism**, not
> shaving bytes. The Nix image contains only the static binary under `/bin`.

### Non-reproducibility of a Docker-style build — demonstrated for real

I did not fabricate two differing Docker image IDs. Instead the **red CI run**
is concrete proof that the *one* thing Docker injects — a wall-clock layer
timestamp — is exactly what breaks a digest. In `build-a` I rebuilt the image
with `created = "2001-01-01T00:00:00Z"` instead of the epoch, changing nothing
else:

```
binary  A: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s   ← unchanged
binary  B: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
image   A: 16141a7552325c2c89c9731713f8b40a9af5e06f9cad78da8228523fa83e8259   ← differs
image   B: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
FAIL: image digests differ — build is not reproducible
```

The binary hash stayed byte-identical; only the layer timestamp moved, and the
image digest diverged. That is precisely why `docker build`, which stamps each
layer with the current time, is non-reproducible — and why
`dockerTools.buildImage` fixes `created` to the epoch.

### Design Questions

**e) What does `docker build` do that introduces non-determinism?**

It records the current wall-clock time as the `created` timestamp of each
image layer and of the image config. Two builds one second apart — even with
`--no-cache` — produce different layer metadata and therefore a different
manifest digest. Any `RUN apt-get`/`apk add` step compounds this, since upstream
package versions drift between builds. The red run above isolates and proves the
timestamp half of this. `dockerTools.buildImage` avoids both: timestamps are
fixed to the epoch and every input is a pinned Nix derivation.

**f) For a security auditor, what does a reproducible image prove that a
signed-but-non-reproducible one cannot?**

A signature proves *provenance* — the image came from a holder of a key — but
says nothing about *what is inside*. The signer could have built from patched
sources or on a compromised host. A reproducible image proves *correspondence*:
any third party clones the repo, runs `nix build .#docker`, and gets the
identical digest, proving the artifact is byte-for-byte what the public source
produces. Signing answers "who built it"; reproducibility answers "is it really
built from this source".

**g) What's the trade-off? Why is `docker build` still the default?**

Nix's cost is a steep learning curve (the language, derivations, flakes),
non-trivial setup (`vendorHash` discovery, installer, best-on-Linux), and a
smaller ecosystem of examples. `docker build` wins by default because every
developer already has Docker, Dockerfiles read top-to-bottom with no new
language, and for most teams a few-byte timestamp difference between builds
causes no practical harm. Nix pays off for security-sensitive software
(firmware, crypto tooling, audited systems) where third-party verification is a
hard requirement.

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
      bin: ${{ steps.hash.outputs.bin }}
      image: ${{ steps.hash.outputs.image }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
      - name: Build binary and image
        run: |
          nix build .#quicknotes -o result-bin
          nix build .#docker -o result-docker
      - name: Smoke test the built binary
        run: |
          SEED_PATH=app/seed.json DATA_PATH="$RUNNER_TEMP/notes.json" ./result-bin/bin/quicknotes &
          pid=$!
          health=""
          for _ in $(seq 1 20); do
            health="$(curl -s http://localhost:8080/health || true)"
            [ -n "$health" ] && break
            sleep 0.5
          done
          echo "HEALTH: $health"
          kill "$pid" 2>/dev/null || true
          case "$health" in *'"status":"ok"'*) echo "smoke OK" ;; *) echo "smoke FAILED"; exit 1 ;; esac
      - name: Compute hashes
        id: hash
        run: |
          echo "bin=$(nix-store --query --hash "$(readlink result-bin)")" >> "$GITHUB_OUTPUT"
          echo "image=$(sha256sum result-docker | awk '{print $1}')" >> "$GITHUB_OUTPUT"
          echo "SIZE image=$(du -Lh result-docker | cut -f1) bin=$(du -Lsh result-bin | cut -f1)"
      - name: Load image into Docker
        run: |
          docker load -i result-docker
          docker image inspect quicknotes:nix \
            --format 'LOADED Entrypoint={{.Config.Entrypoint}} User={{.Config.User}} Ports={{json .Config.ExposedPorts}}'

  build-b:
    # identical to build-a (checkout → install Nix → build → smoke test → hash)
    ...

  verify:
    runs-on: ubuntu-latest
    needs: [build-a, build-b]
    steps:
      - name: Compare digests
        run: |
          echo "binary  A: ${{ needs.build-a.outputs.bin }}"
          echo "binary  B: ${{ needs.build-b.outputs.bin }}"
          echo "image   A: ${{ needs.build-a.outputs.image }}"
          echo "image   B: ${{ needs.build-b.outputs.image }}"
          if [ "${{ needs.build-a.outputs.bin }}" != "${{ needs.build-b.outputs.bin }}" ]; then
            echo "FAIL: binary store hashes differ — build is not reproducible"
            exit 1
          fi
          if [ "${{ needs.build-a.outputs.image }}" != "${{ needs.build-b.outputs.image }}" ]; then
            echo "FAIL: image digests differ — build is not reproducible"
            exit 1
          fi
          echo "OK: both independent runners produced identical binary and image digests"
```

Two parallel jobs on fresh runners, a third job that fails the workflow if
either the binary hash or the image digest differs. The Nix installer is
`cachix/install-nix-action@v31`.

### Green CI run

https://github.com/fleter/DevOps-Intro/actions/runs/29247432975

```
binary  A: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
binary  B: sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
image   A: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
image   B: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
OK: both independent runners produced identical binary and image digests
```

### Red CI run (deliberately broken)

https://github.com/fleter/DevOps-Intro/actions/runs/29246913386

`build-a` was temporarily changed to rebuild the image with
`created = "2001-01-01T00:00:00Z"` instead of the epoch (a genuine timestamp
divergence — the canonical reproducibility break). `build-b` was left untouched.

```
image   A: 16141a7552325c2c89c9731713f8b40a9af5e06f9cad78da8228523fa83e8259
image   B: b7cb98a1f2ce9f37d5ed324237da3305a067a06a5a3f4c028fbcf3d7222e037a
FAIL: image digests differ — build is not reproducible
Error: Process completed with exit code 1.
```

The change was then reverted and the workflow returned to green (the green run
above), confirming the gate is what caught the divergence.

### Design Questions

**h) "Reproducible on my laptop" vs "reproducible in CI"?**

A laptop build shares one persistent Nix store, PATH, and daemon state, so two
runs can match simply because both hit the same local cache — that proves
nothing to a third party, and it is self-reported. CI runs two builds on fresh,
ephemeral runners with empty stores that never see each other's cache. A match
there proves the output is a property of the *pinned inputs*, not of one
machine's state, and any auditor can re-trigger the workflow to check it. The CI
proof is independently verifiable; the laptop proof is folklore.

**i) Why two parallel jobs instead of one job building twice?**

A single job shares one runner's filesystem, Nix store, and environment. The
second `nix build` would hit the store the first one populated and return the
same path without independently rebuilding — a cache hit, not a reproduction.
It could also mask machine-specific determinism bugs (a leaked hostname, PID, or
`$HOME` path) that happen to be constant within one job. Two parallel jobs get
separate runners with empty stores, so identical digests prove reproducibility
across machines, not cache reuse.

**j) Where would the timestamp leak in, and how does `dockerTools.buildImage`
handle it?**

`SOURCE_DATE_EPOCH` is the canonical variable build tools honor to substitute a
fixed timestamp for `time.Now()`. In a plain `docker build` the layer `created`
field comes straight from the daemon's wall clock — no tool consults
`SOURCE_DATE_EPOCH` there, which is why it is non-reproducible. In this flake the
two places a timestamp could leak are (1) the OCI layer/config metadata and (2)
the Go binary's debug info. `dockerTools.buildImage` handles (1) by writing an
explicit `created = "1970-01-01T00:00:00Z"` into the manifest regardless of the
clock; my red run proves that when this is changed, the digest moves. For (2),
`buildGoModule` adds `-trimpath` by default and I pass `-w` to drop DWARF, so no
build path or timestamp is embedded in the binary — proven by the binary hash
staying identical across both runners and even across the red run.

---

## Acceptance Criteria — Evidence Map

| Criterion | Evidence |
|-----------|----------|
| Flake builds via `nix build .#quicknotes` | green run, `build-a`/`build-b` |
| Binary runs, serves `/health` | `HEALTH: {"notes":4,"status":"ok"}` |
| Two independent builds → identical store hash | `binary A == binary B` |
| `flake.lock` committed | `flake.lock` in repo root, real `narHash` |
| `nix build .#docker` → loadable OCI image | `LOADED Entrypoint=[/bin/quicknotes] User=65532:65532 Ports={"8080/tcp":{}}` |
| Two independent builds → identical image digest | `image A == image B` |
| Non-reproducibility demonstrated | red run: timestamp change → digest diverges |
| CI: two parallel jobs assert equal digests | `verify` job |
| Green run AND deliberately-broken red run exist | both linked above |
| Design questions a–j answered | above |
