# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### flake.nix

See `flake.nix` at repo root (committed in this PR).

### Build log

```
$ nix build .#quicknotes
warning: creating lock file "flake.lock":
- Added input 'flake-utils'
- Added input 'nixpkgs' -> github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41 (2026-06-30)
```

### Proof of reproducibility — two independent environments

**Environment A — WSL2 (Ubuntu, host Nix store):**
```
$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

**Environment B — fresh nixos/nix Docker container (isolated Nix store, no shared cache with host):**
```
$ docker run --rm -it -v "$PWD:/repo" -w /repo nixos/nix bash
$ git config --global --add safe.directory /repo
$ nix --extra-experimental-features "nix-command flakes" build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

**Result: identical hashes across two independent environments.**

### Binary runs and serves /health

```
$ ./result/bin/quicknotes &
2026/07/08 16:51:47 quicknotes listening on :8080 (notes loaded: 0)
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
```

### Design questions

**a) Why doesn't `go build` produce bit-identical outputs on two machines, even from the same Git SHA?**

Plain `go build` embeds a build ID into the binary — a hash derived in part from the absolute
filesystem paths of `GOPATH`/`GOCACHE` and the working directory, which differ between machines.
Without `-trimpath`, debug info also embeds these absolute source paths verbatim. Module resolution
can also pull slightly different (but semver-compatible) transitive versions if `go.sum` isn't
fully pinned, though that's not an issue here since QuickNotes has no dependencies. Nix avoids all
of this by building inside a sandboxed, path-normalized environment and by explicitly passing
`-trimpath`.

**b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?**

`vendorHash` is a fixed-output-derivation hash over the vendored Go module dependencies —
i.e., the content that `go mod vendor` would produce from `go.mod`/`go.sum`. It lets Nix fetch
those dependencies from the network once, then verify on every subsequent build that the fetched
content hasn't changed, without needing the network again. Setting `vendorHash = null;` tells Nix
there is nothing to vendor at all — valid here because QuickNotes' `go.mod` declares zero external
dependencies. If a real dependency existed and `vendorHash` were `null`, the build would fail with
a mismatch error showing the actual hash to paste in.

**c) `flake.lock` pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?**

`flake.lock` records the exact commit of every flake input (nixpkgs, flake-utils) that was resolved
the first time the flake was built. Since nixpkgs is a moving target — the same branch reference
(`nixos-25.11`) points to a different commit every day as it receives updates — the lock file is
what turns "roughly this version of nixpkgs" into "exactly this commit, forever." Without it, two
people building the same flake reference on different days would silently get different compiler
and library versions. If deleted before a second build, Nix re-resolves the input to whatever the
latest commit on that branch is at that moment, which will very likely differ from the original
locked revision and can produce a different result.

**d) `buildGoModule` vs `buildGoApplication` — what's the difference? Which would you pick for QuickNotes and why?**

`buildGoModule` is nixpkgs' built-in, first-party function; it fetches all dependencies into one
vendor blob validated by a single `vendorHash`. `buildGoApplication` comes from the external
`gomod2nix` project and instead generates a per-dependency lock file, giving finer-grained caching
(only rebuild what changed) at the cost of requiring an extra external flake input and a
supplementary lockfile generator tool. For QuickNotes — a dependency-free module — the fine-grained
caching benefit of `buildGoApplication` is moot, so `buildGoModule` was chosen for simplicity and
because it needs no additional tooling beyond nixpkgs itself.

---

## Task 2 — Deterministic OCI Image

### flake.nix — the `docker` output

```nix
# buildLayeredImage + fakeRootCommands (not buildImage + runAsRoot)
# deliberately: runAsRoot spins up a real QEMU/KVM VM to get genuine
# root, which fails wherever nested virtualization isn't available
# (e.g. inside a plain Docker container, used here as the second
# independent build environment). fakeRootCommands achieves the same
# chown via a lightweight fakeroot/fakechroot shim instead.
dockerImage = pkgs.dockerTools.buildLayeredImage {
  name = "quicknotes";
  tag = "nix";
  contents = [ quicknotes ];

  fakeRootCommands = ''
    mkdir -p /data
    chown 65532:65532 /data
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = { }; };
    User = "65532:65532";
    WorkingDir = "/";
  };
};
```

### Image loads and runs

```
$ nix build .#docker
$ docker load < result
Loaded image: quicknotes:nix
$ docker run -d --name qn-seed -p 8084:8080 quicknotes:nix
$ curl -s http://localhost:8084/health
{"notes":4,"status":"ok"}
$ docker logs qn-seed
2026/07/09 20:00:02 quicknotes listening on :8080 (notes loaded: 4)
```

### Functional parity with the Lab 6 image

`main.go` resolves `SEED_PATH` (default `seed.json`) relative to `WorkingDir`, and silently falls
back to an empty note list when the file is absent. An image without `/seed.json` therefore starts
cleanly but is *not* functionally equivalent to the Lab 6 one. The flake copies it in via
`extraCommands`, and the container reports `notes loaded: 4` rather than `0` — matching the
Dockerfile-built image's behaviour.

### Proof: identical Nix digests across two independent environments

**Environment A — WSL2 host (`sandbox = true`):**
```
$ nix build .#docker
$ sha256sum result
f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb  result
```

**Environment B — fresh `nixos/nix` container, isolated store:**
```
$ docker run --rm -it --privileged -v "$PWD:/repo" -w /repo nixos/nix bash
$ nix --extra-experimental-features "nix-command flakes" --option sandbox true build .#docker
$ sha256sum result
f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb  result
```

**Identical.**

#### A finding worth recording: the sandbox setting is part of the reproducibility contract

The first attempt at Environment B produced a *different* digest
(`12060e1d9b8954f2ab9ddc4af3cc788840d8196395b0adc15d1128997e748c56`). The cause was not the flake:
the `nixos/nix` image ships with `sandbox = false` (nested user namespaces are unavailable in a
default Docker container), whereas the WSL2 host had `sandbox = true`. Same `flake.lock`, same
nixpkgs revision, same source tree — different builder configuration, different bytes. Running the
container with `--privileged` and `--option sandbox true` made the digests match.

This is a concrete demonstration that `flake.lock` pins the *inputs* but not the *builder's own
configuration*, which is precisely why the CI proof in the bonus task is load-bearing rather than
ceremonial.

### Comparison with Lab 6's `docker build`

Two `--no-cache` builds of the unmodified Lab 6 Dockerfile, back to back on the same machine:

```
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc | grep qn-lab6
qn-lab6  run2  sha256:2f8c4d4683c0cdd22340307aa63a5fc4d3cf879f4a6efb44166e91a0b9e8f499  15.1MB
qn-lab6  run1  sha256:9a95f54a8957c74ddcae9e967a3d4adff7ca61bde34a5fcc4545869a9ef240c9  15.1MB
```

**Different digests**, despite identical source, identical `Dockerfile`, and both base images pinned
by digest (`golang:1.26.4-alpine@sha256:3ad5730…`, `distroless/static:nonroot@sha256:d29e660c…`).

Note what this isolates. The compiled binary itself is *already* built reproducibly inside the
Dockerfile — `-trimpath` strips absolute paths, `-ldflags='-s -w'` drops the symbol table and DWARF
info, `CGO_ENABLED=0` removes libc variance, and the builder image is byte-identical across both
runs. The non-determinism therefore does not come from compilation. It comes entirely from the
**layer packaging step**: BuildKit stamps each exported layer and the image config with the current
wall-clock time, so the tar entries and the resulting content hashes differ between the two runs.

### Image size comparison

| Image | Build method | Size |
|-------|--------------|-----:|
| `qn-lab6:run1` / `run2` | `docker build` (multi-stage → distroless/static:nonroot) | 15.1 MB |
| `quicknotes:nix` | `nix build .#docker` (`dockerTools.buildLayeredImage`) | 21.7 MB |

The Nix image is ~43% larger. This is expected and is a direct consequence of how the two tools
model a "closure." The Dockerfile's second stage starts from `distroless/static` and copies in
exactly two files — the static binary and `seed.json` — discarding everything else the builder
produced. `buildLayeredImage`, by contrast, ships the full Nix store closure of the `quicknotes`
derivation: the binary lives at its `/nix/store/<hash>-quicknotes-0.1.0/` path along with the store
metadata and symlink farm needed to make that path resolvable. Nix trades a few megabytes for the
property that every path in the image is content-addressed and traceable back to a derivation.

(The gap could be narrowed with `pkgs.pkgsStatic`, a slimmer `contents` set, or `streamLayeredImage`
with tuned `maxLayers`, but doing so would obscure the point of the comparison and was left out.)

### Design questions

**e) `dockerTools.buildImage` produces a deterministic image. What does Docker's `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?**

Three things, in descending order of impact.

First and most decisively, **timestamps**. Every layer BuildKit exports is a tar archive whose
entries carry `mtime` values, and the image config records a `created` field — both taken from the
wall clock at build time. Since the layer's content hash is computed over the tar bytes, and the
image digest is computed over the config plus the layer digests, a build one second later yields a
different digest even when every byte of file *content* is identical. Nix's `dockerTools` sidesteps
this by hardcoding `created = "1970-01-01T00:00:01Z"` and normalizing all `mtime`s to the same
constant. That single decision is most of what "deterministic image" means here.

Second, **ambient state leaking through `RUN`**. A `RUN apt-get install ...` resolves against
whatever the upstream repository serves *today*; `RUN curl https://...` fetches whatever is at that
URL *now*. The Dockerfile pins the base image but not the mutable world its `RUN` steps reach into.
Nix builds run in a sandbox with no network access unless the derivation is fixed-output with a
declared hash, which forces every network-fetched input to be content-addressed up front.

Third, **build-environment variance**: file ordering as reported by the host filesystem, umask,
`/etc/hosts`, hostname, the build user's UID, and (in a multi-stage build) which layers happened to
be cached. Nix normalizes all of these inside the sandbox — same UID, same `/build` working
directory, sorted directory traversal.

Worth being precise about the boundary, since this lab's own evidence makes the distinction sharp:
the Go *compilation* in the Lab 6 Dockerfile is already reproducible (`-trimpath`, `-ldflags=-s -w`,
`CGO_ENABLED=0`, digest-pinned builder). It is the packaging around it that is not. `docker build`'s
non-determinism is therefore not a statement about compilers — it is a statement about the image
format's default handling of time.

**f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?**

A signature answers *who* and *whether it changed since*: this artifact was produced by an entity
holding key K, and its bytes have not been altered in transit or at rest. It says nothing about
*what the artifact is*. The auditor must trust that the signer's build machine did what the signer
claims — that the running binary corresponds to the source at the advertised commit, that no
compiler was backdoored, that no attacker with access to the build host injected a payload before
the signing step. Signing authenticates the *end* of the pipeline while leaving the *middle* opaque.
The classic articulation of exactly this gap is Thompson's "Reflections on Trusting Trust."

Reproducibility closes the middle. Given the source and the pinned build recipe, an auditor can
rebuild independently — on their own hardware, with their own Nix store, without ever contacting the
vendor — and check that the digest matches. If it does, they have established, with no trust in the
vendor's infrastructure whatsoever, that the published image is the deterministic function of the
published source. Compromise of the vendor's build host becomes detectable rather than merely
signable. Multiple independent rebuilders (the model the Reproducible Builds project and Debian's
`rebuilderd` implement) turn this into a positive attestation: *N* mutually distrusting parties all
derived the same bytes from the same source, so subverting the artifact now requires subverting all
of them.

Concretely: with a signature alone, the correct response to "did the vendor's CI get compromised in
March?" is "we cannot tell from the artifact." With a reproducible image, the response is "rebuild
the March tag and compare." The property being proven is source-to-binary correspondence, which is
strictly stronger than provenance, and it is unobtainable by signing.

The converse holds too, and is worth stating so the two are not confused: reproducibility does not
subsume signing. It proves the artifact matches *some* source tree; it says nothing about whether
that source tree is the one you want, or who published it. The properties compose — sign a
reproducible artifact and you get both provenance and verifiable correspondence — and neither
substitutes for the other.

**g) What's the trade-off of Nix's reproducibility? Why is `docker build` still the default for most teams?**

The cost is paid in three currencies.

*Learning curve.* Nix requires learning a lazy, purely functional language whose error messages are
notoriously indirect, plus a mental model (derivations, the store, closures, fixed-output
derivations) that has no analogue in the Dockerfile world. A Dockerfile is a shell script with
`FROM` at the top; anyone who knows Linux can read one on first sight. This lab is itself an
existence proof of the friction: a working flake demanded knowing that `buildImage`'s `runAsRoot`
launches a KVM VM and therefore fails inside an unprivileged container, that the escape hatch is
`buildLayeredImage` + `fakeRootCommands` + `enableFakechroot`, and that `sandbox` must be set
consistently across environments or the digests diverge. None of these are discoverable from the
error messages; all three are documented in scattered places.

*Ecosystem friction.* Every dependency must be expressed as a Nix derivation. nixpkgs covers an
enormous amount, but the moment a team needs a vendor SDK, an internal artifact registry, a
proprietary toolchain, or a language ecosystem with weak nixpkgs support, someone has to write and
maintain packaging that would have been three `RUN` lines in a Dockerfile. Ops burden of the store
itself (disk growth, `nix store gc`, running a Cachix or S3 binary cache so CI is not recompiling
from source) is real and ongoing.

*Migration cost against an incumbent that mostly works.* Docker's non-determinism is invisible to
most teams because most teams never need to answer the question reproducibility answers. They pin by
digest, they sign, they scan, and their actual threat model — a dependency with a CVE, a leaked
credential — is addressed by other controls. The marginal value of bit-identical rebuilds is low
until you are shipping to users who must not trust you (Tor, Debian, wallet software, anything where
a compromised build host is a plausible adversary), or until you are subject to a supply-chain
attestation regime (SLSA level 3+, the US Executive Order 14028 SBOM requirements).

And Docker has been closing the gap. BuildKit now honors `SOURCE_DATE_EPOCH` and supports
`--output type=oci,rewrite-timestamp=true`, which gets a meaningful fraction of the way to
determinism for well-behaved Dockerfiles. This weakens the case for switching further, since a team
can adopt the 80% solution without adopting a new language.

The honest summary: `docker build` is the default because it optimizes for the constraint most teams
actually have (get a container shipped, with people who already know bash), while Nix optimizes for
a constraint most teams do not have (prove to a hostile third party that these bytes came from this
source). Nix wins decisively where that second constraint is real, and loses on every other axis.

---

## Bonus Task — CI-Verified Reproducibility

### Workflow

`.github/workflows/nix-repro.yml` (committed in this PR). Structure:

- a `build` job with a two-cell matrix (`replica: [a, b]`), each cell landing on its own fresh
  `ubuntu-24.04` runner;
- each cell installs Nix via `cachix/install-nix-action` pinned by 40-char SHA
  (`a49548c11d9846ad46ecc0115273879b045f001c`, v31), forces `sandbox = true` through
  `extra_nix_config`, builds `.#docker`, and exports `sha256sum result` as a job output;
- a third `compare` job (`needs: build`) reads both outputs and exits non-zero if they differ, or if
  either is empty.

Two details are load-bearing and worth calling out.

`fail-fast: false` on the matrix: with the default (`true`), a divergence that also caused one
replica to fail would cancel the sibling, and the failure would surface as "job cancelled" rather
than as the compare job's explicit mismatch. The gate should fail for the *stated* reason.

The explicit empty-string check in `compare`: matrix jobs share one `outputs` map, so replica A
evaluates `digest_b` to the empty string and vice versa. Two empty strings compare equal. Without
the guard, a workflow in which *both* replicas silently failed to export a digest would pass. The
red run below happens to prove the mechanism works — both keys arrived populated and distinct — but
the guard makes the gate correct rather than merely lucky.

`actions/checkout` is pinned to `11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2), reusing the SHA
already vetted in Lab 3's `ci.yml`.

### Green run

<https://github.com/ivanalpatov2003-design/DevOps-Intro/actions/runs/29046867955>

```
replica a: f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb
replica b: f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb
Reproducible: both replicas produced f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb
```

Note that this digest is identical to the one produced locally on WSL2 and inside the `nixos/nix`
container in Task 2 — three environments, one artifact.

### Red run (deliberate break)

<https://github.com/ivanalpatov2003-design/DevOps-Intro/actions/runs/29047097804>

Replica A only was patched to inject `created = "now"` into the `buildLayeredImage` call before
building — the canonical source of Docker-image non-determinism, stamping the image config with the
wall clock. Replica B was left untouched.

```
replica a: c2be295be336154c101a9711b1c942c28cf7fa0d6884b73e5e4d4a2aaeba04f8
replica b: f5fd0e5466fd99fdc2415a5203319b21ab21a6d2fef472bc67cf9fe9d84af3cb
Error: Reproducibility broken: replica digests differ.
Error: Process completed with exit code 1.
```

Both `build` jobs went **green**; only `compare` went red. Each replica built successfully and had
no way of knowing anything was wrong — the defect exists only in the relation between them. That is
the entire argument for the gate's shape, and it is also the answer to (i) below, demonstrated
rather than asserted.

The break was reverted in `18cb6f8`, and the subsequent run is green again.

### Design questions

**h) What's the difference between "reproducible on my laptop" and "reproducible in CI" that makes the CI proof load-bearing for a security auditor?**

A laptop proof establishes that one machine, configured one way, produced the same bytes twice. What
it silently holds fixed is everything about that machine: the Nix version, `nix.conf`, the contents
of `/nix/store`, the kernel, the filesystem, the locale, whatever happened to be cached. An auditor
cannot inspect any of it, and the developer generally cannot enumerate it either — the confounders
are invisible precisely because they never varied.

This lab produced a clean instance of exactly that failure. Task 2's first cross-environment check
came back with **different** digests, from the same `flake.lock`, the same nixpkgs revision, and the
same source tree. The cause was that the WSL2 host ran with `sandbox = true` while the `nixos/nix`
container shipped `sandbox = false`; the flake pinned its inputs perfectly and said nothing about
the builder's own configuration. Two builds, one flake, two artifacts. On the laptop alone, that
discrepancy is unobservable.

CI makes the proof load-bearing in three ways. It moves the build onto machines the developer does
not own and cannot have pre-seeded, so a compromised or idiosyncratic workstation cannot launder a
bad artifact into a good-looking hash. It forces the environment to be *declared* — the runner
image, the installer SHA, the `extra_nix_config` are all in a file under review, so "reproducible"
acquires a stated scope instead of an implicit one. And it converts a claim made once into an
invariant checked on every push, so the drift that inevitably arrives (a nixpkgs bump, a new Nix
release changing a default) surfaces as a red build rather than as a quiet divergence discovered
months later by whoever first tries to verify a release.

For the auditor the distinction is between "the vendor says it reproduces" and "here is a public,
tamper-evident log showing it reproduced on infrastructure the vendor does not control, under a
configuration I can read." Only the second is evidence.

**i) Why two parallel jobs instead of one job that runs `nix build` twice? What could a single-job two-build comparison miss?**

Because a single job builds twice into the *same* Nix store on the *same* runner, and the second
build is therefore not a build at all. Nix computes the derivation hash from the inputs, finds the
output path already present, and returns it. `sha256sum result` reads the identical file twice. The
check passes unconditionally — it would pass for a flake that is wildly non-reproducible, because it
never actually rebuilds. `--rebuild` forces recomputation and closes that specific hole, but not the
ones below.

Even with `--rebuild`, one job holds constant everything that a second machine would vary: the
runner's kernel, the state of `/nix/store` (which paths are warm), `/tmp` contents, hostname,
process IDs, the wall clock to within seconds, the CPU model, the number of cores available to
parallel builds. Non-determinism that depends on any of these is invisible. Two of the most common
real-world classes — a build that embeds `$(hostname)` or a timestamp with second granularity, and a
build whose output depends on filesystem iteration order or on how many cores drove a parallel
compile — can both survive a same-runner double build and die immediately on two runners.

The sandbox finding from Task 2 is the sharpest illustration: it is a property of the *builder's
configuration*, identical across two builds on one machine by construction, and only detectable by
building somewhere else. A single-job comparison is structurally incapable of catching it.

The red run makes the point concretely: both `build` jobs succeeded. The defect was not visible from
inside either build. It existed only in the comparison across independent executions, which is the
only place reproducibility, as a property, lives.

**j) `SOURCE_DATE_EPOCH` is the canonical env var for forcing build timestamps. Where in your Nix flake would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?**

There are two distinct places a timestamp could enter, and they are handled by different mechanisms.

*Inside the Go build.* `buildGoModule` compiles in the Nix sandbox, where `SOURCE_DATE_EPOCH` is set
to `1` (one second past the Unix epoch) by stdenv, and where the `-trimpath` and `-ldflags "-s -w"`
we pass strip paths and debug info. Go does not embed a build date by default, so this channel is
largely closed already; `SOURCE_DATE_EPOCH` mainly matters here for any tooling that would otherwise
consult the clock, and for the `mtime`s stdenv normalizes on the installed files.

*Inside the image packaging.* This is where the timestamp genuinely wants to leak, and it is the
same place `docker build` leaks it: the tar entries for each layer carry `mtime`, and the image
config carries a `created` field. `dockerTools` does not read `SOURCE_DATE_EPOCH` for these — it
hardcodes them. `created` and `mtime` both default to the literal string `"1970-01-01T00:00:01Z"`,
and every file in the generated layers is normalized to that same instant. That constant is the
whole of Task 2's determinism, and it is why the Nix image reproduces while the Dockerfile image
does not.

The escape hatch proves the rule. Setting `created = "now"` makes `docker images` show a sensible
date instead of "56 years ago", at the cost of a fresh digest on every build. That is precisely the
one-line change used to break replica A in the red run above: it does nothing but restore the
timestamp that Docker never removes, and it is sufficient, on its own, to destroy reproducibility.

(Nix's normalization is stricter than `SOURCE_DATE_EPOCH` alone would be. `SOURCE_DATE_EPOCH` is a
convention a build tool may choose to honour; the sandbox is an enforcement mechanism that also
fixes UID, hostname, `/tmp`, network access, and directory iteration order. Docker's BuildKit has
since adopted `SOURCE_DATE_EPOCH` plus `--output type=oci,rewrite-timestamp=true`, which addresses
the timestamp channel specifically while leaving the others to the Dockerfile author's discipline.)
