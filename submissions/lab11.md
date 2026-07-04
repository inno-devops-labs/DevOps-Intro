# Lab 11 - Reproducible Builds of QuickNotes with Nix

Everything below was built with Nix inside the official `nixos/nix` Docker
image (pinned by digest `sha256:bf1d938835ab96312f098fa6c2e9cab367728e0aad0646ee3e02a787c80d8fb8`,
Nix 2.34.7, `aarch64-linux`). No Nix was installed on the host; the lab
guidelines name the container route as the easiest path to independent
environments, and it also keeps the host untouched.

Two independent environments were used for every proof:

- **Environment A**: a container with the working tree bind-mounted at
  `/repo` and a named Docker volume as its `/nix` store.
- **Environment B**: a throwaway container with the image's pristine store
  and no shared volume, which does a fresh `git clone` of the fork over the
  network and builds from that clone. Nothing except the pushed commits is
  shared with environment A.

The bonus adds a third and fourth environment: two parallel GitHub-hosted
`ubuntu-latest` runners (`x86_64-linux`).

---

## Task 1 - Reproducible Go Build via Nix Flake

### 1.1 The flake

`flake.nix` at the repo root (committed together with `flake.lock`):

```nix
{
  description = "QuickNotes - reproducible Nix build of the DevOps-Intro Go service";

  # Channel pin; flake.lock freezes the exact nixpkgs revision so every clone
  # evaluates the same package set. nixos-25.11 is the newest stable channel
  # and ships go_1_26 = 1.26.4, the same toolchain the Lab 6 Dockerfile uses.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      # Linux only: aarch64 covers local nixos/nix container builds on the
      # Apple Silicon host, x86_64 covers CI runners. The OCI image target
      # is a Linux artifact, so darwin systems are deliberately left out.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
          (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        quicknotes = (pkgs.buildGoModule.override { go = pkgs.go_1_26; }) {
          pname = "quicknotes";
          version = "0.1.0";

          # Only app/ is a build input; nothing else in the repo can change
          # the output hash. Builds the server and the healthcheck probe.
          src = ./app;

          # QuickNotes has zero third-party dependencies. The first build
          # with a fake hash did not return a value to pin; it failed with
          # "vendor folder is empty, please set 'vendorHash = null;'".
          # null skips the vendor derivation entirely, there is nothing to
          # fetch, so nothing needs pinning.
          vendorHash = null;

          # Same knobs as the Lab 6 image build: no cgo so the binary is
          # static, symbols and DWARF stripped.
          env.CGO_ENABLED = "0";
          ldflags = [ "-s" "-w" ];
        };
        default = quicknotes;

        # OCI image built without Docker. The tarball is a pure function of
        # the flake inputs: fixed timestamps, no builder daemon, no network,
        # so two independent builds are byte-identical.
        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";

          # The image gets a writable /tmp for the notes file and the same
          # seed data the Lab 6 image ships.
          extraCommands = ''
            mkdir -m 1777 tmp
            cp ${./app/seed.json} seed.json
          '';

          config = {
            # Exec form; the binary is addressed by its store path inside
            # the image, which pulls the Task 1 package into the layer.
            Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
            ExposedPorts."8080/tcp" = { };
            Env = [
              "DATA_PATH=/tmp/notes.json"
              "SEED_PATH=/seed.json"
            ];
            # Same nonroot uid the Lab 6 distroless image uses. Numeric so
            # no /etc/passwd is needed.
            User = "65532:65532";
          };
        };
      });

      # nix develop drops collaborators into a shell with the pinned
      # toolchain, no global installs needed.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go_1_26 pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
```

Decisions worth calling out:

- **nixpkgs pin**: `nixos-25.11`, which `flake.lock` freezes to revision
  `b6018f87da91d19d0ab4cf979885689b469cdd41`. The channel default `go` is
  1.25.10, but `go_1_26` is available at **1.26.4**, the exact toolchain
  version the Lab 6/9 Dockerfile builder uses (`golang:1.26.4`), so
  `buildGoModule` is overridden to build with it. Same source, same
  compiler version, two build systems.
- **`vendorHash`: a documented deviation.** The lab says to pin the value
  from the first failed build. The first failed build refused to produce
  one:

  ```text
  > go: no dependencies to vendor
  > Running phase: installPhase
  > vendor folder is empty, please set 'vendorHash = null;' in your expression
  ```

  QuickNotes has zero third-party dependencies (`go.mod` has no `require`
  block and no `go.sum` exists), so there is no vendor tree to hash and
  current nixpkgs actively rejects pinning an empty one. `null` is the
  upstream-prescribed spelling of "nothing to fetch". Question b covers
  what the hash would have protected.
- `buildGoModule` passes `-trimpath` on its own and the sandbox provides
  fixed build paths, which is half of the reproducibility story for Go.

### 1.2 Build and run proof (environment A)

```text
$ nix build .#quicknotes --print-build-logs
quicknotes> Running phase: buildPhase
quicknotes> Building subPackage .
quicknotes> Building subPackage ./cmd/healthcheck
quicknotes> Running phase: checkPhase
quicknotes> ok          quicknotes      0.003s
quicknotes> Running phase: installPhase
quicknotes> stripping (with command strip and flags -S -p) in  /nix/store/0hc95vqcxwi993zcs9c4b7hamxpwqgm5-quicknotes-0.1.0/bin

$ ls -l result/bin/
-r-xr-xr-x 1 root root 5410544 Jan  1  1970 healthcheck
-r-xr-xr-x 1 root root 5619248 Jan  1  1970 quicknotes
```

The unit tests (including the Lab 9 security-headers test) run inside the
sandboxed `checkPhase`. The binary serves traffic:

```text
$ ./result/bin/quicknotes &
2026/07/04 08:52:09 quicknotes listening on :8080 (notes loaded: 0)

$ curl -si http://127.0.0.1:8080/health
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff

{"notes":0,"status":"ok"}

$ ./result/bin/healthcheck && echo probe exit 0
probe exit 0
```

The Lab 9 middleware headers are present, which is the fastest possible
check that this is the same hardened source the Docker image ships.

The dev shell works too, and pins the same toolchain:

```text
$ nix develop -c bash -c "go version && gopls version && golangci-lint --version"
go version go1.26.4 linux/arm64
golang.org/x/tools/gopls v0.20.0
golangci-lint has version 2.6.2 built with go1.25.10 from v2.6.2 on 1970-01-01T00:00:00Z
```

(That 1970 build date on golangci-lint is nixpkgs' own timestamp
normalization showing up in a shipped binary.)

### 1.3 Two-environment hash proof

Environment A (bind-mounted working tree, persistent store volume):

```text
$ nix-store --query --hash $(readlink result)
sha256:0n7wlzxw92b1a13zdh96i9c2gavv6g55zv76014b8bn7p57vsinx
```

Environment B (pristine store, fresh shallow clone from GitHub):

```text
$ git clone --depth 1 -b feature/lab11 https://github.com/Dekart-hub/DevOps-Intro qn-fresh
$ cd qn-fresh && nix build .#quicknotes
$ readlink result
/nix/store/0hc95vqcxwi993zcs9c4b7hamxpwqgm5-quicknotes-0.1.0
$ nix-store --query --hash $(readlink result)
sha256:0n7wlzxw92b1a13zdh96i9c2gavv6g55zv76014b8bn7p57vsinx
```

Identical store path and identical NAR hash,
`sha256:0n7wlzxw92b1a13zdh96i9c2gavv6g55zv76014b8bn7p57vsinx`, from two
stores that never shared a byte. Notably, environment A built from the
dirty working tree before the commit and environment B from the pushed
commit; content-addressing does not care how the bits arrived.

### 1.4 Design questions

**a) Why does `go build` not produce bit-identical outputs on two
machines, even from the same Git SHA?**
Several inputs leak into the binary that are not part of the source:
absolute paths of the module cache and GOPATH end up in DWARF and panic
strings unless `-trimpath` is set; the embedded build ID is derived from
the toolchain binaries, so any difference in Go patch version or how Go
was installed changes it; `-buildvcs` stamps the commit, the dirty flag
and the VCS time into the binary; and with cgo enabled the host linker
and libc versions get involved. Two machines rarely agree on all of
those. Nix pins the toolchain to the store path level, builds in a
sandbox with a fixed directory layout, hands `buildGoModule` a
VCS-less store copy of the source and sets `-trimpath`, which removes
every item on that list.

**b) `vendorHash` is a SHA over what, exactly? What happens if you set
`vendorHash = null;`?**
It is the SRI hash of the NAR serialization of the `vendor/` tree that
`go mod vendor` produces inside a fixed-output derivation. That is the
one derivation allowed network access, and the hash is the leash: if the
module proxy returns even one different byte tomorrow, the build fails
with a hash mismatch instead of silently compiling different code.
`vendorHash = null` skips that derivation entirely, so the build gets no
network and compiles with only what is in `src`. For a project with
dependencies that would fail; for QuickNotes it is the correct spelling,
and current nixpkgs enforces it: the "first failed build" printed the
demand for `null` rather than a value to pin.

**c) Why is `flake.lock` the single most important file for
reproducibility? What happens if you delete it before the second build?**
The flake pins `nixos-25.11`, but that is a moving branch name.
`flake.lock` freezes it to commit
`b6018f87da91d19d0ab4cf979885689b469cdd41` plus its content hash, and
with it the entire world the build sees: compiler, stdenv, coreutils,
`dockerTools` itself. Delete the lock and the second build re-resolves
the branch to whatever it points at that day; a nixpkgs bump to Go
1.26.5 would change the toolchain, the store paths and every output
hash, and the two builds would diverge while both being "correct".
Committing `flake.nix` without `flake.lock` is pinning by vibes.

**d) `buildGoModule` vs `buildGoApplication`; which one for QuickNotes?**
`buildGoModule` ships with nixpkgs and models all dependencies as one
fixed-output vendor derivation guarded by `vendorHash`; simple, zero
extra tooling, but the single hash must be re-pinned on any dependency
change and nothing is shared between projects. `buildGoApplication`
(from the gomod2nix project) generates a per-dependency lockfile
(`gomod2nix.toml`), giving each module its own cacheable derivation and
removing the manual hash dance, at the cost of an external tool and a
second lockfile to keep in sync. For QuickNotes the choice is easy:
there are zero dependencies, so gomod2nix would be pure overhead.
`buildGoModule` with `vendorHash = null` describes the situation in one
line.

---

## Task 2 - Deterministic OCI Image

### 2.1 The image output

The `docker` package in the flake above (`pkgs.dockerTools.buildImage`)
meets the requirements like this:

- **QuickNotes binary from Task 1**: `Entrypoint` references
  `${quicknotes}/bin/quicknotes`, which pulls the Task 1 store path (and
  only its runtime closure) into the layer.
- **Exec-form entrypoint** and **`ExposedPorts."8080/tcp"`** are set in
  `config`.
- **nonroot**: `User = "65532:65532"`, the same uid the Lab 6 distroless
  image uses, numeric so the image needs no `/etc/passwd`. The notes file
  goes to `/tmp/notes.json` (`mkdir -m 1777 tmp` in `extraCommands`), so
  uid 65532 can write it.
- **Built without Docker**: `nix build .#docker` runs entirely inside the
  Nix sandbox and emits a `docker load`-able tarball; no daemon involved.

### 2.2 Two-environment digest proof

Environment A:

```text
$ nix build .#docker && sha256sum result
093f2295f10eab9de2189bcb99e6602b056fc8ff2fd8603dabf429e1cd6cb8ab  result
```

Environment B (pristine store, fresh clone, same commands):

```text
$ sha256sum result
093f2295f10eab9de2189bcb99e6602b056fc8ff2fd8603dabf429e1cd6cb8ab  result
```

Byte-identical tarballs (5207143 bytes) from two independent stores. As a
bonus data point, forcing a rebuild with a hostile environment variable
does not move the digest, because the sandbox scrubs the caller's env:

```text
$ SOURCE_DATE_EPOCH=1234567890 nix build .#docker --rebuild && sha256sum result
093f2295f10eab9de2189bcb99e6602b056fc8ff2fd8603dabf429e1cd6cb8ab  result
```

### 2.3 The image is a real image

```text
$ docker load < qn-nix-image.tar.gz
Loaded image: quicknotes:nix

$ docker inspect qn-nix --format 'User={{.Config.User}} ...'
User=65532:65532
Entrypoint=["/nix/store/0hc95vqcxwi993zcs9c4b7hamxpwqgm5-quicknotes-0.1.0/bin/quicknotes"]
Ports={"8080/tcp":{}}

$ curl -si http://localhost:8093/health
HTTP/1.1 200 OK
X-Content-Type-Options: nosniff
{"notes":4,"status":"ok"}

$ curl -s http://localhost:8093/notes | head -c 170
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll
containerize, deploy, monitor, and harden across all 10 labs." ...
```

The seeded notes and the Lab 9 headers are served from the loaded image,
running as uid 65532.

### 2.4 Comparison with the Lab 6 Dockerfile build

Two fresh `--no-cache` builds of the same Dockerfile from the same
working tree:

```text
$ docker build --no-cache -q -t qn-lab6:run1 ./app
sha256:5671df9345f5603f665e099967212affc073edcd298745a3a8767a7924599783
$ docker build --no-cache -q -t qn-lab6:run2 ./app
sha256:2b5e38db29eb28fa4d7d6220b3481fc6619aceb25f1dee19580bba665b9ddda3

$ docker images --no-trunc qn-lab6
qn-lab6:run2 sha256:2b5e38db29eb28fa4d7d6220b3481fc6619aceb25f1dee19580bba665b9ddda3 22.1MB
qn-lab6:run1 sha256:5671df9345f5603f665e099967212affc073edcd298745a3a8767a7924599783 22.1MB
```

Same Dockerfile, same source, same machine, minutes apart: **two
different image IDs**, exactly as the lab predicts. The Nix image
produced the same digest across two machines-worth of separation; the
Docker image cannot even agree with itself.

Size comparison:

| Image | How measured | Size |
|---|---|---|
| `quicknotes:nix` | compressed tarball (`nix build .#docker` output) | 5.2 MB |
| `quicknotes:nix` | `docker images` after load (unpacked) | 31.8 MB |
| `qn-lab6` (distroless) | `docker images` (unpacked) | 22.1 MB |

The Nix image is somewhat larger unpacked because nixpkgs' Go links
runtime references to full `tzdata` (2.0 MiB), `iana-etc` (557 KiB) and
`mailcap` (116 KiB) store paths into the closure
(`nix path-info -rsSh` shows a 13.2 MiB closure; the rest of the
difference is layer accounting), while distroless ships a hand-trimmed
equivalent set. The reading's "usually ~10-30 MB" holds; hyper-optimized
distroless still wins on raw size, Nix wins on knowing exactly why every
byte is there.

### 2.5 Design questions

**e) What does `docker build` do that introduces non-determinism, even
from the same Dockerfile + Git SHA?**
The classic offenders: every layer tar embeds the mtimes of files as
they were created during that run; the image config and per-instruction
history carry wall-clock `created` timestamps; `RUN apt-get install`
style steps fetch whatever the mirror serves that day (our Dockerfile
avoids that, but the pattern is the default); base tags like
`golang:1.26.4` are mutable references that can be re-pushed; and
BuildKit adds its own metadata. In our runs the Go binary inside both
images was very likely identical (`-trimpath`, pinned toolchain); the
image IDs still diverged purely from timestamps. `dockerTools`
normalizes all of it: file mtimes and image `created` are fixed to the
epoch, there is no daemon and no network, so the output is a pure
function of the inputs.

**f) What can an auditor prove with a reproducible image that a
signed-but-non-reproducible image cannot give them?**
A signature proves *who* published the artifact and that it was not
modified afterwards. It proves nothing about what happened *before*
signing: a compromised build host or maintainer signs a backdoored
artifact just as happily (the xz-utils lesson). A reproducible image
proves *correspondence to source*: any third party can rebuild the
audited source and byte-compare digests, so a backdoor injected between
source and artifact has nowhere to hide. Signature answers "authentic?",
reproducibility answers "is this exactly the code I audited?"; supply
chain trust wants both.

**g) The trade-off, and why `docker build` is still the default?**
Costs of the Nix route: a genuinely unusual language and mental model,
dense error messages, slow cold builds (mitigated only by operating a
binary cache like Cachix), rough edges in some ecosystems, and one more
toolchain the whole team must learn. `docker build` is preinstalled in
every CI, understood by every engineer, and "same-ish image every time"
is good enough for most products, especially when scanning, signing and
provenance attestations (Labs 9 and 10 territory) already cover the
risks teams actually get audited on. Reproducibility pays off where the
threat model includes the build system itself; most teams rationally
spend that effort elsewhere.

---

## Bonus - CI-Verified Reproducibility

### B.1 Workflow

`.github/workflows/nix-repro.yml` (full file in the diff): triggers on
`push` to any branch and on `pull_request`; jobs `build-a` and `build-b`
each check out the repo (`actions/checkout` pinned to
`df4cb1c069e1874edd31b4311f1884172cec0e10`, v6.0.3), install Nix with the
Determinate installer action (`DeterminateSystems/nix-installer-action`
pinned to `ef8a148080ab6020fd15196c2084a2eea5ff2d25`, v22), run
`nix build .#docker` and publish `sha256sum result` as a job output. A
third job `compare` needs both, prints both digests, refuses to pass if
either is empty, and fails on mismatch.

One deliberate deviation from the lab's sketch: the two builders are two
explicitly named jobs, not a two-cell matrix. Matrix cells share a single
outputs namespace, so the second cell's digest silently overwrites the
first and the comparison degenerates into `x == x`. Two named jobs keep
the outputs distinct.

### B.2 Green run

Two fresh `x86_64-linux` runners agreed on the digest:

```text
runner a: c6b783734f6351bfff15c909491e9aca4869624994dd756a6c1058a8d1351790
runner b: c6b783734f6351bfff15c909491e9aca4869624994dd756a6c1058a8d1351790
identical digests, build is reproducible
```

Run: https://github.com/Dekart-hub/DevOps-Intro/actions/runs/28701333164

(The CI digest differs from the local `093f2295...` one by design: the
runners build the `x86_64-linux` flake output, the laptop containers the
`aarch64-linux` one. Reproducibility claims always attach to one
platform.)

### B.3 Red run: the gate catches a divergence

The lab suggests breaking one job with a different `SOURCE_DATE_EPOCH`.
Measured first, locally: an env var cannot break this build, because the
Nix sandbox never lets it reach the compiler (see the digest-stable
`SOURCE_DATE_EPOCH=1234567890 nix build --rebuild` proof in 2.2). That
non-result is the design of Nix working as intended, so the red demo
breaks something the sandbox *does* respect: the source itself. On demo
branch `lab11-repro-break`, `build-a` gets one extra step before its
build:

```yaml
      - name: Deliberately drift this runner's source (red demo)
        run: echo "// drift for the lab 11 red demo" >> app/store.go
```

Runner A now builds a genuinely different program than runner B, both
builds succeed individually, and the gate is the only thing standing:

```text
runner a: 05f3e88514fa4d37a3fa65aac1be8eabd5a9f271b13832feda9fcb396d117e10
runner b: c6b783734f6351bfff15c909491e9aca4869624994dd756a6c1058a8d1351790
build is NOT reproducible across runners
```

Run: https://github.com/Dekart-hub/DevOps-Intro/actions/runs/28701345152
(job `digests must match` red, workflow failed). A detail worth noticing:
the undrifted runner B reproduced the green run's digest exactly, so
across the two runs four independent runners agreed on
`c6b78373...351790` and only the deliberately drifted build diverged.
The demo branch was deleted afterwards; the run log persists.

### B.4 Design questions

**h) What makes "reproducible in CI" load-bearing for an auditor where
"reproducible on my laptop" is not?**
A laptop double-build is one machine agreeing with itself: same store,
same architecture, same accumulated state, and the evidence is a
screenshot the auditor must take on faith. The CI proof runs on two
clean, ephemeral, independently provisioned machines the auditor can
inspect (public logs, pinned workflow definition), and it re-executes on
every push, so the claim is continuously re-verified rather than
asserted once. It also removes the "works on the maintainer's machine
because of the maintainer's machine" class of impurity.

**i) Why two parallel jobs instead of one job running `nix build`
twice?**
Because the second `nix build` in the same job is a no-op: the
derivation hash is unchanged, the output is already in the local store,
and Nix returns the same path without building anything. The comparison
becomes `sha256sum result` twice on one file - vacuously green. Even
forcing `--rebuild` only proves determinism *on that runner*: same
kernel, same CPU, same runner image. Two parallel jobs are two
independent machines with independent stores, which is the actual claim
reproducibility makes.

**j) Where would `SOURCE_DATE_EPOCH` normally leak in, and how does
`dockerTools.buildImage` handle it?**
Timestamps leak wherever a builder stamps "now" into bytes: file mtimes
in layer tars, gzip headers, and the image config's `created` and
per-layer history fields; `SOURCE_DATE_EPOCH` is the convention build
tools honor to fake that clock deterministically. `dockerTools`
does not need to be asked: it fixes the image `created` time and layer
file mtimes to the epoch instead of reading the clock. And one level
below, the Nix sandbox launches builders with a scrubbed environment, so
a `SOURCE_DATE_EPOCH` exported on the runner never reaches the build at
all - measured in 2.2, and the reason the red demo had to drift the
source instead.
