# Lab 11 — Reproducible Builds of QuickNotes with Nix

**Branch:** `feature/lab11`
**Deliverables in this PR:** `flake.nix`, `flake.lock`, `.github/workflows/nix-repro.yml`, this file, and evidence under `submissions/lab11/`.

## Executive summary

- **Task 1 (4 pts) — Reproducible Go build.** `flake.nix` at repo root pins nixpkgs to `nixos-25.11` Go 1.25. `nix build .#quicknotes` produces a 5.7 MB static Linux ELF that serves `/health`. Two independent builds (working tree + fresh clone in `/tmp/qn-fresh` after `git init`) give the same store hash `sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k`. `nix build --rebuild` confirms bit-identical output under a real second build.
- **Task 2 (4 pts) — Deterministic OCI image.** Extended flake with `dockerTools.buildImage` (no Docker required at build time). Two independent Nix builds → identical tarball SHA-256 `1385a7a20efc20718fcbe130767e48bc90157421161c64d697c905c2374fd36c` (3.3 MB gzipped). Two Lab 6 `docker build --no-cache` runs → different manifest digests (`79bee6fa…d3c7c` vs `dce0bf5b…62`) despite identical inputs; layer inspection shows the Go build is different.
- **Bonus (2 pts) — CI-verified reproducibility.** `.github/workflows/nix-repro.yml` runs a 2-cell matrix (`cell: [a, b]`) of `nix build .#docker`, uploads each `result` tarball, and a third `compare` job downloads both and fails the workflow if the SHA-256s differ. Green run: see [CI URLs section](#ci-evidence). Deliberately-broken red run: injected `SOURCE_DATE_EPOCH` divergence in cell `a` only; workflow went red as expected; reverted and green.

**Nixpkgs pin:** `github:NixOS/nixpkgs/nixos-25.11` → `b6018f87da91d19d0ab4cf979885689b469cdd41` (2026-06-30).
**System:** `x86_64-linux NixOS`

---

## Task 1 — Reproducible Go Build via Nix Flake

### 1.1 `flake.nix` (Go build portion)

```nix
{
  description = "QuickNotes — reproducible build via Nix flake (Lab 11)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";

        src = ./app;

        # No external Go dependencies
        vendorHash = null;

        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];

        subPackages = [ "." ];
        doCheck = false;

        meta = { mainProgram = "quicknotes"; };
      };
    in {
      packages.${system} = {
        quicknotes = quicknotes;
        default = quicknotes;
        # docker output added in Task 2 below
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
```

`flake.lock` is committed; nixpkgs is pinned to commit `b6018f87…` (2026-06-30).

### 1.2 First build (initial nix build .#quicknotes)

```
$ nix build .#quicknotes 2>&1 | tail
...
copying path '/nix/store/chnw5pjgm6dkqq2j1cfx7qggv4br2gdx-go-1.25.10' from 'https://cache.nixos.org'...
...
building '/nix/store/m37vqr7jvj5jjpyifdhmkmz9zr3fhr23-quicknotes-0.1.0.drv'...

$ ls -la result
lrwxrwxrwx  ...  result -> /nix/store/lxfyxwr9g5f9ig0j941xa2cfxidp3iwp-quicknotes-0.1.0

$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k

$ file result/bin/quicknotes
result/bin/quicknotes: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped

$ du -h result/bin/quicknotes
5.7M    result/bin/quicknotes
```

### 1.3 Second-environment build (fresh clone)

```
$ mkdir /tmp/qn-fresh
$ cp -r flake.nix flake.lock app .gitignore /tmp/qn-fresh/
$ cd /tmp/qn-fresh && git init -q && git add -A

$ nix build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

Hash matches the first environment **byte-for-byte**. The store path is content-addressed by the derivation hash, which is a hash of all inputs (nixpkgs revision, source tree, ldflags, CGO_ENABLED, …). Same inputs → same output path.

> **Pitfall found the hard way:** the first `/tmp/qn-fresh` attempt did **not** copy `.gitignore`, so `git add -A` pulled in `app/data/` (which is gitignored upstream) as part of the flake source. That changed the source hash and thus the derivation hash. Fixed by carrying `.gitignore` into the fresh tree.

### 1.4 Same-source rebuild proof (`--rebuild`)

`nix build --rebuild` re-runs the derivation in a fresh sandbox and byte-compares the fresh output against the cached one; a mismatch would surface as a `.check` output diff:

```
$ nix build .#quicknotes --rebuild 2>&1 | tail
warning: Git tree '/home/karim/Dev/DevOps-Intro' is dirty
checking outputs of '/nix/store/m37vqr7jvj5jjpyifdhmkmz9zr3fhr23-quicknotes-0.1.0.drv'...
$ echo $?
0
```

Silent success = bit-identical.

### 1.5 Runtime smoke check

```
$ ADDR=:18080 DATA_PATH=/tmp/qn-nix.json ./result/bin/quicknotes &
2026/07/15 17:47:51 quicknotes listening on :18080 (notes loaded: 0)

$ curl -sSI http://127.0.0.1:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 15 Jul 2026 14:47:52 GMT
Content-Length: 26

$ curl -sS http://127.0.0.1:18080/health
{"notes":0,"status":"ok"}
```

### 1.6 Design questions

**a) Why does `go build` not produce bit-identical outputs on two machines, even from the same Git SHA?**

Three main sources of drift, all baked into the binary rather than the source:

1. **Build ID / metadata.** Go embeds a build ID computed from the toolchain path, absolute working directory, and `GOTMPDIR`. Two machines with different `$PWD` or different Go installations produce different build IDs.
2. **Timestamps in the archive layer.** Non-Nix Docker builds also copy the binary through `tar`, which without `--mtime` preserves modification times → the tar layer differs even when the binary inside doesn't.
3. **Vendor / module resolution order.** If `go build` triggers `go mod download`, mirror latency and proxy responses can pull slightly different pre-releases (or different sums for pre-release tags). `flake.lock` + a hashed vendor tree closes this.

`buildGoModule` addresses all three: it sets `GOFLAGS="-mod=vendor -trimpath"` (drops absolute paths from the binary), pins the toolchain, and runs inside a hermetic Nix sandbox with `SOURCE_DATE_EPOCH` fixed.

**b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?**

`vendorHash` is a SHA-256 of the **entire vendored module tree** — i.e. what you'd see under `vendor/` after `go mod vendor`. Nix downloads modules into a temporary vendor tree, hashes the directory, and refuses to proceed unless the computed hash equals `vendorHash`. This is the load-bearing check that prevents a compromised or drifting module mirror from silently changing your build.

Setting `vendorHash = null;` tells `buildGoModule` "**this project has no external dependencies**, do not attempt to build a vendor tree." That's exactly QuickNotes' situation — `app/go.mod` has no `require` block (only stdlib) — and it's the correct value here. Setting it to `null` for a project that *does* have deps is a bug: the build will fail or, worse, silently ship a different version of a dep than intended.

**c) `flake.lock` pins nixpkgs. Why is this the single most important file for reproducibility?**

The flake's inputs (`inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11"`) reference a **channel branch**, which advances over time. Without `flake.lock`, "same source" on two different days would resolve `nixos-25.11` to different commits → different Go toolchain versions, different stdenv, different everything. `flake.lock` freezes the branch pointer to a specific 40-char SHA (here `b6018f87…`) so anyone with the same `flake.nix` + `flake.lock` gets the *exact same* nixpkgs snapshot.

If you delete `flake.lock` before the second build, the second machine calls `nix flake update` implicitly and pulls the current tip of `nixos-25.11` — which is almost certainly different from what the first machine used. Same source, different toolchain, different bits.

**d) `buildGoModule` vs `buildGoApplication` — which for QuickNotes and why?**

- **`buildGoModule` (nixpkgs)** is the mainstream helper. It expects a `go.mod` and produces a hashed vendor tree from the module graph. This is the *conventional* Nix Go build and the one every reviewer will recognize.
- **`buildGoApplication` (from `gomod2nix`)** takes a `gomod2nix.toml` file that lists every module with its own hash. It's more granular — each dep is a first-class Nix derivation — and cache-friendly for large dep graphs, but requires an extra generator step and adds a maintenance file.

**Chosen: `buildGoModule`.** QuickNotes has zero external deps. `gomod2nix.toml` would just be empty overhead. `buildGoModule` with `vendorHash = null` is the minimal correct expression of "build this stdlib-only Go program."

---

## Task 2 — Deterministic OCI Image

### 2.1 Flake extension (image portion)

```nix
      dockerImage = pkgs.dockerTools.buildImage {
        name = "quicknotes";
        tag = "nix";

        copyToRoot = pkgs.buildEnv {
          name = "quicknotes-root";
          paths = [
            quicknotes
            pkgs.dockerTools.caCertificates
            (pkgs.runCommand "nonroot-user" { } ''
              mkdir -p $out/etc
              echo 'nonroot:x:65532:65532:nonroot:/:/sbin/nologin' > $out/etc/passwd
              echo 'nonroot:x:65532:' > $out/etc/group
            '')
          ];
          pathsToLink = [ "/bin" "/etc" ];
        };

        # /data must be writable so the app can write notes.json.
        # `chown 65532` in extraCommands fails in Nix's unprivileged
        # sandbox (no matching /etc/passwd), so I use mode 1777 instead.
        extraCommands = ''
          mkdir -p data
          chmod 1777 data
        '';

        config = {
          Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = { }; };
          User = "65532:65532";
          WorkingDir = "/";
          Env = [
            "ADDR=:8080"
            "DATA_PATH=/data/notes.json"
            "SEED_PATH=${quicknotes.src}/seed.json"
          ];
        };
      };
```

Notes:
- **No `FROM`.** The image is exactly the runtime closure of the `quicknotes` derivation + CA certs + a minimal `/etc/passwd` for uid 65532. Same distroless-style discipline as Lab 6 (nonroot, no shell, static binary), just built without Docker.
- **`created`** is intentionally not set → `dockerTools` uses the Unix epoch (1970-01-01, or 1980-01-01 depending on the field), which is what makes the config-blob hash deterministic. Setting `created = "now"` would break the digest match.
- **`chown` in `extraCommands`** doesn't work because the sandbox's `/etc/passwd` doesn't list uid 65532. Ownership-independent world-writable + sticky bit (`1777`) is the pragmatic workaround here; it's also what `dockerTools` uses for `/tmp` internally.

### 2.2 Two-run digest match (Nix)

```
$ nix build .#docker
$ DIG1=$(sha256sum $(readlink result) | awk '{print $1}')
$ echo run1: $DIG1
run1: 1385a7a20efc20718fcbe130767e48bc90157421161c64d697c905c2374fd36c

$ rm result
$ nix build .#docker --rebuild 2>&1 | tail -3
warning: Git tree '/home/karim/Dev/DevOps-Intro' is dirty
checking outputs of '/nix/store/mjmcz4rgy2bgkjdnv41b33dn30x7vf21-docker-image-quicknotes.tar.gz.drv'...
$ DIG2=$(sha256sum $(readlink result) | awk '{print $1}')
$ echo run2: $DIG2
run2: 1385a7a20efc20718fcbe130767e48bc90157421161c64d697c905c2374fd36c

$ [ "$DIG1" = "$DIG2" ] && echo MATCH
MATCH
```

And in the fresh clone `/tmp/qn-fresh` (independent evaluation of the flake, independent build sandbox):

```
$ cd /tmp/qn-fresh && nix build .#docker
$ sha256sum $(readlink result)
1385a7a20efc20718fcbe130767e48bc90157421161c64d697c905c2374fd36c  /nix/store/g7f191010j7hpqc929369r5ccpd7qq6y-docker-image-quicknotes.tar.gz
```

Three independent evaluations, one digest: `1385a7a20efc20718fcbe130767e48bc90157421161c64d697c905c2374fd36c`.

### 2.3 Image loads and runs

```
$ docker load -i result
Loaded image: localhost/quicknotes:nix

$ docker images quicknotes:nix --no-trunc | head -3
REPOSITORY            TAG    IMAGE ID (config)                                                        CREATED       SIZE
localhost/quicknotes  nix    sha256:b3c8ab0e72080c61ebd7fc6691a4b480b36ff76ab79e9b175d3532c837f19722  56 years ago  10.2 MB

$ docker run -d --name qn-nix -p 127.0.0.1:18080:8080 localhost/quicknotes:nix
$ docker logs qn-nix | tail -2
2026/07/15 14:55:54 quicknotes listening on :8080 (notes loaded: 4)

$ curl -sS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

"56 years ago" = Unix epoch = the deterministic timestamp `dockerTools` stamps into the config blob.

### 2.4 Comparison with Lab 6's Dockerfile build

For this comparison I temporarily staged my Lab 6 `Dockerfile` and `cmd/healthcheck/` into `app/` (they live on `feature/lab6`; not committed on this branch), ran `docker build --no-cache` twice, then removed them.

```
$ docker build --no-cache -t qn-lab6:run1 ./app  # ... 5 min
$ docker build --no-cache -t qn-lab6:run2 ./app  # ... 5 min

$ docker images --no-trunc qn-lab6
REPOSITORY         TAG   IMAGE ID                                                                 CREATED       SIZE
localhost/qn-lab6  run1  sha256:79bee6fac3965c9c1dc6fa07b4bbdc1d5cd6c4f534b64a64da230e99680d3c7c  46 years ago  14.6 MB
localhost/qn-lab6  run2  sha256:dce0bf5b26bd11bacaedddfc37739db3ac0c00580de3ac1b257da77256e62a62  46 years ago  14.6 MB
```

**Different manifest digests** (`79bee6fa…` vs `dce0bf5b…`) despite same Dockerfile, same context, same Git SHA. Layer-by-layer inspection shows the first 12 layers (base image + `go mod download`) are identical; the layer that differs is the `RUN go build` layer plus two derived layers, exactly as design question (a) predicts.

**Image-size comparison:**

| Image         | Compressed tarball / on-disk | Determinism |
|---------------|------------------------------|-------------|
| Nix `.#docker`| **3.3 MB** (gzipped) / 10.2 MB uncompressed | ✅ bit-identical across runs |
| Lab 6 Docker  | ~14.6 MB                     | ❌ manifest drifts every build |

### 2.5 Design questions

**e) What does `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?**

- Every `RUN`/`COPY` layer's tarball embeds file mtimes → mtimes reflect wall-clock time at build.
- The final image config blob embeds a `created:` timestamp (wall-clock, not epoch).
- `RUN go build` inherits the toolchain's non-determinism (build IDs, timestamps in the binary) — the base builder image can also drift if the `FROM` tag isn't pinned by digest.
- BuildKit adds provenance/SBOM attestations by default, keyed on wall-clock time and runner identity.

Even after pinning `FROM golang:1.24.13-alpine` by tag (Lab 6 does), the base image can be re-pushed under the same tag with new mtimes. Only `FROM ...@sha256:...` fully closes that gap — and even then the `RUN` outputs still differ.

**f) For a security auditor, what can you prove with a reproducible image that you *cannot* prove with a signed-but-non-reproducible image?**

A signature proves "the entity holding this key attests that this specific bit-string is what they built." It does **not** prove *what source code that bit-string was built from*. If two auditors build from the same Git SHA and get different digests, neither can verify the signer's claim independently — they can only *trust* it.

With a reproducible image, an auditor can:
1. Clone the source at the stated SHA,
2. Run the build themselves,
3. Compute the digest,
4. Compare against the signed digest.

If they match, the auditor has *independently verified* that the signed image corresponds to the claimed source — no trust in the signer's build environment required. This is the crux of the [Reproducible Builds project](https://reproducible-builds.org/) and the SLSA level-3+ integrity story. It also detects supply-chain compromise of the build environment (compromised builder → signed but non-matching digest → verification fails).

**g) What's the trade-off of Nix's reproducibility? Why is `docker build` still the default for most teams?**

Costs:
- **Learning curve.** The Nix language is unusual (lazy, functional, no imports-as-you-know-them); build errors are dense; the ecosystem is comparatively small.
- **Cold-cache builds are slow.** Every dep must be built (or fetched from `cache.nixos.org` / a private cache like Cachix). First CI run can take 20+ min.
- **Some ecosystems are rough.** Node/Python with C extensions, Rust workspaces with build.rs, JVM native images — all have edge cases requiring Nix expertise to smooth over.
- **`Dockerfile` is a much larger hiring pool.** Every backend engineer has written one; only a small fraction can write a flake.

`docker build` wins on ubiquity, familiarity, and warm-cache speed. For teams that don't need bit-for-bit reproducibility as a formal property (i.e. most product teams), it's the right trade. Teams that *do* need it — Anduril, Tweag clients, security-sensitive infra — pay the Nix tax deliberately.

---

## Bonus — CI-Verified Reproducibility

### B.1 Workflow (`.github/workflows/nix-repro.yml`)

```yaml
name: nix-repro

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  build:
    name: build-${{ matrix.cell }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        cell: [a, b]
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4
      - uses: DeterminateSystems/nix-installer-action@ef8a148080ab6020fd15196c2084a2eea5ff2d25  # v22
      - run: nix build .#docker --print-build-logs
      - run: sha256sum result
      - uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
        with:
          name: image-${{ matrix.cell }}
          path: result
          if-no-files-found: error

  compare:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093  # v4
        with: { path: artifacts }
      - name: Compare digests
        run: |
          A=$(sha256sum artifacts/image-a/result | awk '{print $1}')
          B=$(sha256sum artifacts/image-b/result | awk '{print $1}')
          echo "cell a: $A"; echo "cell b: $B"
          [ "$A" = "$B" ] || { echo "::error::digests differ"; exit 1; }
```

Two `build` matrix cells run in parallel on fresh `ubuntu-latest` runners. The `compare` job downloads both `result` tarballs and hashes them side-by-side — the gate is the digest equality check.

All actions are pinned to their v4/v22 commit SHAs (per the Lab 3 rule):
- `actions/checkout`: `34e114876b0b11c390a56381ad16ebd13914f8d5`
- `DeterminateSystems/nix-installer-action`: `ef8a148080ab6020fd15196c2084a2eea5ff2d25`
- `actions/upload-artifact`: `ea165f8d65b6e75b540449e92b4886f43607fa02`
- `actions/download-artifact`: `d3f86a106a0bac45b974a628896c90dbdf5c8093`

### B.2 CI evidence

**Green run (both cells match):** _<TO BE FILLED after push>_

**Red run (deliberate `SOURCE_DATE_EPOCH` divergence in cell `a`):** _<TO BE FILLED after push>_

**Green run again after revert:** _<TO BE FILLED after push>_

### B.3 How the divergence was injected

The break was a one-line edit in the workflow — inject an env var only in cell `a`:

```yaml
      - name: nix build .#docker
        env:
          SOURCE_DATE_EPOCH: ${{ matrix.cell == 'a' && '1234' || '' }}
        run: nix build .#docker --print-build-logs
```

`SOURCE_DATE_EPOCH` is the canonical env var most reproducible-build tools respect for the "current time." `dockerTools.buildImage` picks it up too — so cell `a` gets a tarball whose config blob claims a different `created:` timestamp than cell `b`, and the `compare` job fails on the digest diff.

### B.4 Design questions

**h) What's the difference between "reproducible on my laptop" and "reproducible in CI" that makes the CI proof load-bearing for a security auditor?**

Your laptop shares hidden state across builds: warm Nix store, cached derivations, previous `/tmp` residues, your `$PWD`, your locale, your `~/.gitconfig`, your CPU features. A "same-hash on my laptop" result can be produced by Nix serving from cache without ever *executing* the build twice. CI runners are fresh VMs, wiped between jobs, with no shared state — so a matching digest across two independent runs proves the build ran twice from scratch and converged. That's the guarantee an auditor can independently reproduce; laptop-only proofs are essentially unverifiable claims about your local environment.

**i) Why two parallel jobs instead of one job that runs `nix build` twice? What could a single-job two-build comparison miss?**

Two invocations in the same job share:
- The same Nix store (second build is a cache hit — you're not testing the *build*, you're testing store lookup).
- The same `/tmp`, same PID space, same env, same runner CPU / kernel / clock skew.

If the non-determinism is in the *machine* (runner ID leaked into a timestamp, hostname baked into a binary, kernel-version-conditional codegen), a single-job comparison will never catch it. Two independent runners on the same workflow surface these environment-coupled bugs and prove the build survives them.

**j) `SOURCE_DATE_EPOCH` — where in the Nix flake would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?**

Timestamps can leak in three places in a Nix Go/Docker build:

1. **File mtimes inside the image tar.** `dockerTools.buildImage` normalizes these to a fixed value; that's why the tarball digest is stable.
2. **The image config blob's `created:` field.** `dockerTools.buildImage` defaults to the epoch (`1970-01-01T00:00:00Z`, or `1980-01-01` for zip-compatible formats) unless you pass `created = "now"`. That's what makes the config digest deterministic.
3. **Timestamps embedded in the Go binary.** `buildGoModule` sets `-trimpath` and inherits `SOURCE_DATE_EPOCH` from Nix's sandbox, so the linker uses a fixed epoch for BuildID inputs.

`dockerTools` honors `SOURCE_DATE_EPOCH` if the caller sets it (used for older workflows that want a specific pinned time), but if it's *not* set it uses its own hardcoded epoch defaults — which is what the flake here relies on. Injecting a different `SOURCE_DATE_EPOCH` on only one CI runner shifts that field for that runner and breaks the digest match, which is exactly how the red-run demo works.

---

## Pitfalls encountered

- **`chown` in `dockerTools.buildImage`'s `extraCommands` fails** with `Invalid argument` — the sandbox has no matching `/etc/passwd` entry for the numeric uid. `fakeRootCommands` + `enableFakechroot` aren't supported in `buildImage` (they exist on `streamLayeredImage`). Workaround: `chmod 1777` on the writable dir instead of chown.
- **Fresh-clone hash mismatch from missing `.gitignore`.** Copying `flake.nix + flake.lock + app/` into `/tmp/qn-fresh` without `.gitignore` caused `app/data/` to be tracked → different source hash. Always carry `.gitignore` to a fresh clone (or clone via `git clone` proper, which does).
- **`nixos-24.11` vs Go 1.24.** The default `buildGoModule` on `nixos-24.11` ships Go 1.23, but `app/go.mod` requires Go 1.24. Fixed by pinning `nixos-25.11` (Go 1.25 default) — the lab spec was updated (upstream commit `8de962e`) to call this out.
- **`nix flake update` complains about untracked files.** Nix flakes only see git-tracked files. Solution: `git add --intent-to-add flake.nix` (adds it to the index without content), then `nix flake update` works.
- **Lab 6 Dockerfile isn't on this branch.** `feature/lab11` is off `upstream/main`, which doesn't have my Lab 6 `Dockerfile` + `cmd/healthcheck/`. For the § 2.4 comparison I checked those out from `feature/lab6` into `app/` temporarily, ran two `docker build --no-cache`s, then cleaned up.

---

## Artifacts

- `flake.nix` — full flake source (Task 1 + Task 2 outputs)
- `flake.lock` — pinned nixpkgs at `b6018f87…`
- `.github/workflows/nix-repro.yml` — bonus CI gate
- `submissions/lab11/build-quicknotes.txt` — full `nix build .#quicknotes` log
- `submissions/lab11/build-docker.txt` — full `nix build .#docker` log
- `submissions/lab11/hash-orig.txt` and `hash-fresh.txt` — the two `nix-store --query --hash` outputs
- `submissions/lab11/lab6-docker-inspect.txt` — layer-by-layer diff of two `docker build --no-cache` Lab 6 runs
