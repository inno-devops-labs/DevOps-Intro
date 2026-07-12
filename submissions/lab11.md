# Lab 11 — Reproducible Builds of QuickNotes with Nix

Flake at the repo root: [`../flake.nix`](../flake.nix) (+ `flake.lock`, pinning the
exact `nixos-24.11` nixpkgs revision). Built inside `nixos/nix` (Nix isn't native
on Windows; the container is the lab's recommended path).

---

## Task 1 — Reproducible Go Build via Nix Flake

### The flake

`packages.quicknotes` builds `./app` with `pkgs.buildGoModule`:
`vendorHash = null` (QuickNotes has zero external deps — nothing to vendor),
`CGO_ENABLED = 0` (static), `ldflags = [ "-s" "-w" ]`. A `devShells.default`
exposes `go`, `gopls`, `golangci-lint` for `nix develop`.

### Reproducibility proof — two independent builds, identical store hash

```text
# build A
$ nix build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1105i4ql5529h1bbbsabva6kzvc2rhq657vrjdzm868mrh41kd4d

# build B — rebuilt from scratch and verified
$ nix build --rebuild .#quicknotes    # exit 0 => output is bit-identical
$ nix-store --query --hash $(readlink result)
sha256:1105i4ql5529h1bbbsabva6kzvc2rhq657vrjdzm868mrh41kd4d   # identical to A
```

`nix build --rebuild` is Nix's native reproducibility check: it rebuilds the
derivation and **fails with a hash mismatch if the output differs** — so a clean
exit *is* the proof of a bit-identical rebuild.

### It runs

```text
$ DATA_PATH=/tmp/notes.json ./result/bin/quicknotes &
2026/07/12 12:48:52 quicknotes listening on :8080 (notes loaded: 0)
$ ./result/bin/quicknotes healthcheck ; echo $?     # in-binary probe of /health
0                                                    # exit 0 = serving OK
```

(The Nix-built binary is statically linked — `patchelf` reports "most likely
statically linked", confirming `CGO_ENABLED=0`.)

### 1.3 Design questions

**a) Why doesn't `go build` produce bit-identical output on two machines?**
Several leaks: (1) the **Go toolchain version** differs per machine → different
codegen; (2) **absolute paths** get baked into the binary (GOROOT/GOPATH, the
build directory) unless you pass `-trimpath`, so a different checkout dir yields a
different binary; (3) **dependency resolution** can drift — without a committed
`go.sum`/vendor dir, the module proxy may hand back different versions; (4) the
embedded **build ID** derives from those inputs. Nix removes all of it: it pins
the exact Go version (from nixpkgs), builds in a sandbox with fixed paths, and
vendors dependencies deterministically — same inputs in, same bytes out.

**b) `vendorHash` is a SHA over what? What if it's `null`?**
It's a **fixed-output hash over the complete set of vendored dependencies** — the
exact bytes of every module Go pulls for the build. Pinning it lets Nix fetch
deps in a network-allowed fixed-output derivation and guarantees the same
dependency tree every time. `vendorHash = null` tells `buildGoModule` the module
has **no dependencies to vendor** and skips the vendor derivation entirely —
correct for QuickNotes (no `go.sum`, zero deps). Set `null` on a module that
*does* have deps and the build fails (it can't find the vendored packages).

**c) Why is `flake.lock` the single most important file for reproducibility?**
`inputs.nixpkgs.url = "…nixos-24.11"` is a **moving branch**; `flake.lock` freezes
it to one exact git commit. Because the *entire* build environment — the Go
compiler, stdenv, coreutils, every build flag — comes from that pinned nixpkgs,
the lock is what makes "same inputs" literally true across clones and machines.
**Delete it before the second build** and Nix re-resolves `nixos-24.11` to
whatever the branch points at *now* (a newer commit) → a different Go/stdenv →
a potentially different output hash. No lock, no reproducibility.

**d) `buildGoModule` vs `buildGoApplication` — which for QuickNotes?**
`buildGoModule` (in nixpkgs) uses Go modules and vendors all deps through one
fixed-output derivation keyed by `vendorHash` — self-contained, no extra tooling.
`buildGoApplication` (from `gomod2nix`) instead turns `go.mod`/`go.sum` into a Nix
expression with **one derivation per dependency** (finer caching, no single
vendorHash) but needs the `gomod2nix` tool and a generated file. For QuickNotes —
**`buildGoModule`**: with zero dependencies there's nothing to vendor and no
`vendorHash` to maintain (`null`), so the per-dependency granularity of
`buildGoApplication` buys nothing. Simplest correct choice.

---

## Task 2 — Deterministic OCI Image

### The flake output

`packages.docker` uses `pkgs.dockerTools.buildImage` (no Docker needed) to pack
the Task 1 binary: `Entrypoint = [ "/bin/quicknotes" ]`, `ExposedPorts 8080/tcp`,
`User = "65534:65534"` (nonroot), `Env` sets `DATA_PATH=/tmp/notes.json` and a
world-writable `/tmp` so the nonroot app can persist. No `created` timestamp is
set, so it defaults to the Unix epoch → a stable digest.

### Reproducibility proof — identical SHA-256 across two builds

```text
$ nix build .#docker ; sha256sum result
3a16430ecc46f6d9fac8b858e8ea10bbb2f3967d33fd631779442ad35d9ec11c
$ nix build --rebuild .#docker ; sha256sum result
3a16430ecc46f6d9fac8b858e8ea10bbb2f3967d33fd631779442ad35d9ec11c   # identical

# loadable + runs, nonroot, correct config:
$ docker load < result ; docker run -p 8097:8080 quicknotes:nix ; curl :8097/health
{"notes":0,"status":"ok"}   # 200
$ docker inspect quicknotes:nix --format '{{.Config.User}} {{json .Config.ExposedPorts}} {{json .Config.Entrypoint}}'
65534:65534 {"8080/tcp":{}} ["/bin/quicknotes"]
```

### Contrast — Lab 6's `docker build` is NOT reproducible

```text
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6 --format '{{.Tag}} {{.ID}}'
run1 sha256:60cb2a84bea1a47eea144ed0560e98107dba770caee175da489846cd0b8134c5
run2 sha256:47bdf5144556c042e63e38e3180896ad940d9714d22e965608278a75a230ccbb   # ≠ run1
```

Two `--no-cache` builds of the *same* Dockerfile + source → **different image
IDs** (layer/config timestamps), while two Nix builds are byte-identical.

Image size: Nix-built **8.44 MB** vs Lab 6 distroless **8.56 MB** — essentially the
same (both are just the static binary), but only the Nix one is bit-reproducible.

### 2.4 Design questions

**e) What does `docker build` do that introduces non-determinism?**
Plenty, even from the same Dockerfile + Git SHA: it stamps each layer and the
image config with **build timestamps** (`created`); `RUN` steps execute in a live
environment where `apt`/`go`/network fetch **whatever is current** (unpinned
package versions, moving mirrors); file **mtimes** and ordering land in the tar
layers; and base images referenced by tag can move. `dockerTools.buildImage`
sidesteps all of it — it assembles the layer tar from Nix store paths with
normalized timestamps (epoch) and no `RUN`, so the bytes are a pure function of
the inputs.

**f) What can a reproducible image prove that a signed-but-non-reproducible one can't?**
A signature proves **who** built/published the image and that it wasn't altered
*after* signing — but you must **trust the builder** that the bytes match the
source. A reproducible image proves **the bytes correspond to this exact source**:
anyone can rebuild from the pinned inputs and get the identical digest, so an
auditor can independently verify "this artifact is what the source compiles to"
without trusting the build machine. Signing answers *provenance*; reproducibility
answers *"does the binary actually match the audited source?"* — it closes the
gap where a compromised build server signs a backdoored image.

**g) The trade-off — why is `docker build` still most teams' default?**
Nix's cost is a **steep learning curve** and ecosystem friction: you write Nix,
pin `vendorHash`, manage the store, and many tools/registries assume a Dockerfile.
`docker build` is universally understood, works with every base image and CI, and
"good enough" for teams whose threat model doesn't demand bit-for-bit
verifiability. Reproducibility is a real cost you pay up front for a guarantee
most teams don't (yet) require — so Dockerfiles win on ergonomics and ubiquity.

---

## Bonus — CI-Verified Reproducibility

Not attempted (Task 1 + Task 2 completed).
