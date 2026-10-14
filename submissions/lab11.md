# Lab 11 submission

Both environments are containers, so Nix never had to be installed on the
laptop. Environment A is `nixos/nix` with the working copy bind-mounted.
Environment B is a second `nixos/nix` container with an empty store that
fetches the flake from GitHub and never sees the working copy at all.

## Task 1: reproducible Go build

`flake.nix` is at the repository root and `flake.lock` is committed next to
it: [flake.lock](../flake.lock). The flake has three outputs: the `quicknotes`
package, which is also `default`, the `docker` image of Task 2, and a devShell
with go, gopls and golangci-lint for `nix develop`.

```nix
{
  description = "Reproducible builds of QuickNotes";

  # One input, one lock entry. flake.lock pins this to an exact nixpkgs
  # revision, which is what makes two builds on two machines comparable.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            # Only app/ is the source. Nothing else in the repository can
            # change the build result.
            src = ./app;

            # go.mod declares no dependencies, so there is nothing to vendor
            # and no vendor derivation to hash. null is the correct value
            # here, not a placeholder.
            vendorHash = null;

            # A static binary, the same choice as the Lab 6 Dockerfile.
            # It goes inside `env` because buildGoModule already places
            # CGO_ENABLED there, and a second copy as a plain derivation
            # argument is rejected as a duplicate.
            env.CGO_ENABLED = 0;

            # Drop the symbol table and the DWARF data. Smaller output, and
            # fewer places for build paths to hide.
            ldflags = [ "-s" "-w" ];

            # go test ./... runs inside the build, so a broken test fails the
            # package instead of shipping.
            doCheck = true;

            meta = {
              description = "QuickNotes, the course project service";
              mainProgram = "quicknotes";
            };
          };

          # The seed file has to be in the image, because the app reads it at
          # start to fill an empty store.
          seed = pkgs.runCommand "quicknotes-seed" { } ''
            mkdir -p $out
            cp ${./app/seed.json} $out/seed.json
          '';
        in
        {
          inherit quicknotes;
          default = quicknotes;

          # An OCI image built with no Docker involved. dockerTools writes the
          # tarball itself and sets every timestamp to the epoch, so the
          # digest depends only on the contents.
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            copyToRoot = [ quicknotes seed ];

            # The app needs one writable directory for its data file. The
            # image has no shell, so it is created here instead.
            extraCommands = ''
              mkdir -p tmp
              chmod 1777 tmp
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = { }; };
              # Numeric, because the image has no /etc/passwd to look a name
              # up in. Same user as the Lab 6 image.
              User = "65532:65532";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/tmp/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
```

### Build log

```
$ docker run --rm -v "$PWD:/repo" -w /repo nixos/nix sh -c \
    "nix build .#quicknotes --print-build-logs && nix-store --query --hash $(readlink result)"

these 49 paths will be fetched (143.2 MiB download, 561.6 MiB unpacked):
  ...
  /nix/store/9y14bfcz45kfvisfqhzim8irxj5bx0bz-go-1.25.10
  ...
building '/nix/store/ab2zfa2l0akpr6ms0wfm3sq3cxq7qw9r-quicknotes-0.1.0.drv'...
quicknotes> Running phase: buildPhase
quicknotes> Building subPackage .
quicknotes> Running phase: checkPhase
quicknotes> ok          quicknotes      0.004s
quicknotes> Running phase: installPhase
quicknotes> Running phase: fixupPhase
quicknotes> patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
sha256:0qd4klg5q3hn2malql089wdq1cm39ndclxbj10689vzdqwg82f62
```

Two things worth pointing at. The check phase runs `go test ./...` inside the
build, so a failing test fails the package. And patchelf reporting no
`.dynamic` section is the proof that `CGO_ENABLED = 0` took effect: the binary
is static.

### Identical store hashes from two independent environments

Environment A, the working copy on the laptop:

```
$ nix build .#quicknotes && nix-store --query --hash $(readlink result)
sha256:0qd4klg5q3hn2malql089wdq1cm39ndclxbj10689vzdqwg82f62
```

Environment B, a fresh container with an empty Nix store, building straight
from the fork on GitHub:

```
$ docker run --rm -e NIX_CONFIG="experimental-features = nix-command flakes" nixos/nix sh -c '
    b=$(nix build github:aniksel/DevOps-Intro/feature/lab11#quicknotes --no-link --print-out-paths)
    echo "quicknotes: $b"
    nix-store --query --hash $b'

unpacking 'github:aniksel/DevOps-Intro/3135248292ead734c4f3a004e5f5f4610fbf634a' into the Git cache...
quicknotes: /nix/store/wa5h3908gd904ir412a272h8br6927y3-quicknotes-0.1.0
sha256:0qd4klg5q3hn2malql089wdq1cm39ndclxbj10689vzdqwg82f62
```

Same hash, and the same store path name, which already encodes every input.

### It runs

```
$ docker run -d --name qn-nix -v nixstore-a:/nix -v "$PWD:/repo" -w /repo -p 8081:8080 nixos/nix \
    sh -c 'SEED_PATH=/repo/app/seed.json DATA_PATH=/tmp/notes.json ADDR=:8080 $(readlink -f result)/bin/quicknotes'

$ curl -s http://localhost:8081/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:8081/notes | head -c 160
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01
```

The binary is Linux aarch64, so it runs in a container rather than on the
laptop, with the Nix store kept in a named volume.

### Design questions

**a) Why `go build` is not bit-identical on two machines**

Five things leak in.

The build path. The compiler records the directory the source was built in, so
`/home/anna/project` and `/home/bob/src` give different bytes. `-trimpath`
removes it, which is why the Lab 6 Dockerfile already uses that flag.

The build ID. The linker writes an identifier derived from the inputs,
including the toolchain, so a different Go patch release changes it.

The toolchain itself. Two machines rarely run the same Go down to the patch,
and the standard library is compiled into the binary.

VCS stamping. Since Go 1.18 the toolchain stamps the commit, whether the tree
was dirty, and the build time, unless `-buildvcs=false` is passed. Two builds a
minute apart differ.

Dependency resolution. Without a lock for the whole environment, a version
range resolves to whatever is newest today.

Nix removes all five. The source is a store path, the toolchain is a store path
pinned by `flake.lock`, the build runs in a sandbox with a fixed environment,
and nothing may reach the network during the build.

**b) What `vendorHash` hashes, and what `null` does**

It is a hash over the vendor directory Nix builds from `go.mod` and `go.sum`:
every module source at the declared version, laid out under `vendor/`. That
step is a fixed-output derivation, the only kind of derivation allowed to use
the network, and the hash is what makes that safe. If an upstream module ever
changed its contents, the hash would stop matching and the build would stop.

`null` switches the vendor step off. Nix then expects the build to need no
modules, either because the repository already contains `vendor/` or because
there are no dependencies. If there are dependencies and none are vendored, the
build fails when the compiler tries to fetch them, because the sandbox has no
network.

For QuickNotes `null` is the correct value and not a placeholder. `app/go.mod`
has a module line and a go directive and nothing else, so there is nothing to
fetch and nothing to hash. The first build confirms it: no hash mismatch
appears.

**c) Why `flake.lock` is the most important file**

Because it is the only thing that fixes what nixpkgs means. The flake asks for
the branch `nixos-25.11`, which is a moving pointer. The lock records the exact
revision `b6018f8`, and every build that reads the lock gets that revision: the
Go compiler, the linker, bash, coreutils, the whole environment.

Delete it before the second build and that machine resolves `nixos-25.11` to
whatever the branch points at that day. One Go patch release of drift is enough
to change the store path. Worse, the build still succeeds, so the mismatch
looks like a reproducibility failure rather than a missing file.

The environment B build above shows the same thing from the other side. It
never saw the working copy. It read the flake and the lock from GitHub and
still landed on the same store path.

**d) `buildGoModule` versus `buildGoApplication`**

`buildGoModule` lives in nixpkgs. It takes the source, builds one vendor
directory from `go.mod` and `go.sum`, and pins the whole dependency set with a
single hash.

`buildGoApplication` comes from gomod2nix. It turns `go.sum` into a Nix
expression with one derivation per module, so every dependency is its own store
path and can be fetched and cached separately.

QuickNotes uses `buildGoModule`. There are no dependencies here, so splitting
them per module buys nothing. It is also already in nixpkgs, which means no
extra flake input and no generated file to keep in sync.
`buildGoApplication` pays off on a big dependency tree. There, one changed
module should not throw away the whole vendor build.

---

## Task 2: deterministic OCI image

The `docker` output of the same flake, built by `pkgs.dockerTools.buildImage`:

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";
  copyToRoot = [ quicknotes seed ];

  extraCommands = ''
    mkdir -p tmp
    chmod 1777 tmp
  '';

  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = { }; };
    User = "65532:65532";
    Env = [
      "ADDR=:8080"
      "DATA_PATH=/tmp/notes.json"
      "SEED_PATH=/seed.json"
    ];
  };
};
```

No Docker takes part in building it. Nix writes the tarball itself.

### Identical digests from two independent environments

Environment A:

```
$ nix build .#docker --no-link --print-out-paths
tarball: /nix/store/5migxd11h1nq7ykckr4lga6cavqlikih-docker-image-quicknotes.tar.gz
$ sha256sum $d
d36024b690ee69eb938bf4a05fe1f69791d283cc6ecd017a5d6a7f62b06b7972
$ du -h $d
2.8M
```

Environment B, fresh container, source from GitHub:

```
tarball: /nix/store/5migxd11h1nq7ykckr4lga6cavqlikih-docker-image-quicknotes.tar.gz
d36024b690ee69eb938bf4a05fe1f69791d283cc6ecd017a5d6a7f62b06b7972
```

### The image loads and runs

```
$ docker run --rm -v nixstore-a:/nix -v "$PWD:/repo" -w /repo nixos/nix sh -c \
    'cat $(nix build .#docker --no-link --print-out-paths)' | docker load
Loaded image: quicknotes:nix

$ docker run -d --name qn-nix-img -p 8081:8080 quicknotes:nix
$ curl -s http://localhost:8081/health
{"notes":4,"status":"ok"}
```

### The same Dockerfile built twice is not reproducible

```
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6

REPOSITORY  TAG   IMAGE ID                                                                 SIZE
qn-lab6     run2  sha256:780157b4796f64bf7db84825d10fe296d0776da55de75435cad5327e37c9a31a  15.8MB
qn-lab6     run1  sha256:b13ae4036298b2ca4fbaf546e34052d0124416351e3e6a15c992af53e7b74fd3  15.8MB
```

Same Dockerfile, same commit, same machine, seconds apart, and two different
digests. The Nix build gave the same digest on two different machines.

### Size

| | Nix image | Lab 6 Docker image |
|---|---|---|
| tarball on disk | 2.8 MB | not produced |
| as `docker images` reports | 20.8 MB disk, 9.19 MB content | 15.8 MB |

The two numbers are not the same measurement, so the comparison is rough. The
Lab 6 image is a scratch image holding two stripped binaries, the application
and its healthcheck. The Nix image holds one binary plus the layout
`dockerTools` writes around it. Size is not where Nix wins here, determinism
is.

### Design questions

**e) What `docker build` does that is not deterministic**

The image config records a `created` timestamp and layer entries carry mtimes,
so two builds a second apart produce different bytes and a different digest.
The two runs above show exactly that.

Timestamps are only the visible part. The build is not isolated. Every `RUN`
runs against the state of the world at that moment, with network access, so a
package manager can pull something newer. A `FROM` tag moves unless it is
pinned by digest. Build arguments, the environment and the order in which files
land in the context all feed the result.

`dockerTools.buildImage` does the opposite on every count. The tarball is put
together from store paths that are already fixed. Every timestamp is written as
the epoch, entries go in a sorted order, and nothing runs with network access.

**f) What a reproducible image proves that a signature cannot**

A signature proves who published the artifact and that nobody changed it
afterwards. It says nothing about what is inside or where it came from.

A reproducible image lets anyone rebuild from the source and get the same
digest. The auditor no longer has to trust the publisher, the build machine or
the CI system. If the digest matches, the artifact is that source and nothing
else.

That is the gap a signed-only pipeline leaves open. A compromised build server
produces a correctly signed artifact with an extra line nobody wrote in it, and
the signature verifies perfectly. With reproducibility the audit is a rebuild:
run it yourself, compare the digest, and one injected byte shows up.

**g) The trade-off, and why `docker build` is still the default**

The cost is the learning curve and the ecosystem.

Nix is a language of its own. It is lazy, and its error messages assume the
reader already knows how derivations work. The Lab 6 Dockerfile can be read by
anyone who has seen a shell. This flake cannot, and a team takes it on only if
somebody is willing to look after it.

Nix also has to own every input. Anything outside nixpkgs needs packaging
first, and the sandbox that produces reproducibility is the same sandbox that
blocks the quick network fetch a Dockerfile would do in one `RUN`.

Then there is reach. Every CI provider, every registry and every tutorial
assumes a Dockerfile. Nix has a smaller cache, a smaller community, and fewer
people who can debug it at 3 am.

`docker build` stays the default because it is good enough for most teams. They
pin base images by digest, they trust their build servers, and the
reproducibility they actually need is "the application behaves the same", which
a Dockerfile does deliver. Bit-for-bit identity starts to matter when an
auditor or a regulator asks for it.
