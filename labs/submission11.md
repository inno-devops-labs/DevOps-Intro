# Lab 11 Submission — Reproducible Builds with Nix

> All tasks including the bonus were completed. Source files live under [labs/lab11/app/](lab11/app/).

## Environment note

The host machine (WSL2 / Ubuntu 24.04) did not have a password-less `sudo`, so the Determinate Systems installer could not escalate in non-interactive mode. Instead of installing Nix on the host, I ran every Nix command inside the official `nixos/nix:latest` Docker image (`nix (Nix) 2.34.6`) with the project directory bind-mounted. This is a legitimate Nix setup — the sandbox, store semantics, and binary cache all work the same way — and it actually surfaced a real-world observation about `import <nixpkgs>` that I documented in Task 1.4.

```bash
$ docker run --rm nixos/nix:latest nix --version
nix (Nix) 2.34.6

$ docker run --rm nixos/nix:latest \
    nix --extra-experimental-features 'nix-command flakes' run nixpkgs#hello
Hello, world!
```

---

## Task 1 — Build Reproducible Artifacts from Scratch (6 pts)

### 1.1 — Installation & verification

Verified with `nix --version` → `nix (Nix) 2.34.6`. The `nix run nixpkgs#hello` smoke test downloaded the package from `cache.nixos.org` and printed `Hello, world!`, confirming both binary-cache access and experimental features.

### 1.2 — The Go application

[main.go](lab11/app/main.go):

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    fmt.Printf("Built with Nix at compile time\n")
    fmt.Printf("Running at: %s\n", time.Now().Format(time.RFC3339))
}
```

The `time.Now()` call is intentional — it keeps *runtime* output non-deterministic, proving that reproducibility is a property of the **build output**, not the program behavior.

A matching [go.mod](lab11/app/go.mod) declares `go 1.21` (the version available in the flake-pinned `nixos-23.11` channel used in the bonus task).

### 1.3 — The Nix derivation

[default.nix](lab11/app/default.nix):

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "nix-app";
  version = "1.0.0";

  src = ./.;

  # No external Go modules → no vendor tree to hash.
  vendorHash = null;

  meta = with pkgs.lib; {
    description = "Simple Go app demonstrating Nix reproducibility";
    license = licenses.mit;
  };
}
```

**Why each attribute matters:**

- `pkgs ? import <nixpkgs> {}` — parameterised input. In Task 1 it comes from the NIX_PATH channel (intentionally **un-pinned** for Task 1.4's observation); in the bonus Flake it comes from a locked revision.
- `buildGoModule` — the canonical nixpkgs helper for Go. It runs `go build` inside the sandbox, with network access disabled, so any external dependency must be declared via `vendorHash`.
- `src = ./.` — the entire current directory is hashed and copied into `/nix/store/<hash>-source`. If any byte of `main.go` or `go.mod` changes, every downstream hash changes.
- `vendorHash = null` — explicit assertion that there are no Go modules to fetch. If you forget this for a project that *does* have deps, Nix refuses to build.

### 1.4 — Proof of reproducibility

Two consecutive builds in fresh `nixos/nix` containers:

```bash
# Build 1
$ nix-build default.nix
/nix/store/ak6fsqmf96cgsxwsjzcmryca0mr5ciar-nix-app-1.0.0
$ ./result/bin/app
Built with Nix at compile time
Running at: 2026-04-23T22:22:24Z
$ sha256sum ./result/bin/app
f1dacb662dbb0f9ac7ff51acc544d5a77e89972a017fa720cb6c56409d974ca8  ./result/bin/app

# Build 2 (fresh container, fresh download)
$ nix-build default.nix
/nix/store/y40wnqlivjxf7rnqfbgxhxc59135ax6f-nix-app-1.0.0
$ sha256sum ./result/bin/app
f1dacb662dbb0f9ac7ff51acc544d5a77e89972a017fa720cb6c56409d974ca8  ./result/bin/app
```

**What this shows — the interesting part:**

| Artifact | Build 1 | Build 2 | Identical? |
| -------- | ------- | ------- | ---------- |
| Binary SHA-256 | `f1dacb66…74ca8` | `f1dacb66…74ca8` | ✅ **Yes** |
| Nix store path | `ak6fsqmf…` | `y40wnqli…` | ❌ No |

The **binary contents are bit-for-bit identical** (Go compiles deterministically, `buildGoModule` passes `-trimpath` and strips the binary). But the store-path hashes differ because each fresh Docker container resolved `<nixpkgs>` from the system channel and landed on a different nixpkgs snapshot. The *output* reproduced; the *derivation closure* did not.

This is exactly the failure mode that motivates **Flakes** (see Bonus Task), which add a `flake.lock` to pin nixpkgs to a specific revision — yielding identical store paths too.

### Docker comparison — why Docker is *not* reproducible

[Dockerfile](lab11/app/Dockerfile):

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

```bash
$ docker build -t test-app .
$ docker inspect test-app --format='{{.Id}}'
sha256:1aff0447673182fd6c99b6812bd7ea41e37726bf9096308923a2d6948c32904c

$ docker build -t test-app . --no-cache
$ docker inspect test-app --format='{{.Id}}'
sha256:6b7809d3d32eeb0a96a96ca0abb59e29bb596462cab647e9f264954332cf21d4
```

Two builds of the same `Dockerfile` with the same `main.go`, two different image IDs. Docker's non-reproducibility comes from:

1. **Layer timestamps** — every `RUN`/`COPY` records `created` metadata.
2. **Base-image drift** — `FROM golang:1.22` resolves to whatever digest the registry currently points that tag at.
3. **Non-sandboxed builds** — the Go compiler runs with access to the host's `/tmp`, `/var`, network, environment variables; any leakage ends up in layer hashes.
4. **Cache semantics** — with a warm cache, `RUN` commands are *skipped*; with `--no-cache`, they re-execute and produce slightly different output.

### What makes Nix builds reproducible

- **Content-addressable store.** The path `/nix/store/<hash>-name-version` has its `<hash>` computed from *every input* (source, compilers, flags, all transitive dependencies). Same inputs → same hash, *by construction*.
- **Sandboxed builds.** The builder runs in a Linux namespace with no network, no `/home`, no `/tmp`, no environment leakage. Only declared inputs are visible.
- **No timestamps.** Nix's stdenv sets `SOURCE_DATE_EPOCH`, patches out `__DATE__`/`__TIME__` in C builds, and strips mtime on installed files.
- **Pure functions.** A Nix expression is a pure function `inputs → output`; a builder that reads anything outside its declared inputs is rejected.

### Anatomy of a Nix store path

Take `/nix/store/ak6fsqmf96cgsxwsjzcmryca0mr5ciar-nix-app-1.0.0`:

| Segment | Meaning |
| ------- | ------- |
| `/nix/store/` | Root of the content-addressable store (always this prefix). |
| `ak6fsqmf96cgsxwsjzcmryca0mr5ciar` | 32-character, base-32-encoded, truncated hash of **all inputs to the derivation** — source tree hash, every dependency's store path, every build flag. |
| `nix-app` | `pname` attribute from the derivation. |
| `1.0.0` | `version` attribute from the derivation. |

The hash isn't of the *output*; it's of the derivation's *inputs*. That's what lets Nix check the binary cache (`cache.nixos.org`) *before* building — if someone else built the same inputs, just download the result.

---

## Task 2 — Reproducible Docker Images with Nix (4 pts)

### 2.1 — `docker.nix`

[docker.nix](lab11/app/docker.nix):

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in

pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
    # Note the absence of `created = "now"` — keeping the default epoch
    # timestamp is what makes the resulting image reproducible.
  };
}
```

**Key differences from a plain `Dockerfile`:**

- `buildLayeredImage` builds a tarball directly (no daemon involved), then `docker load` ingests it.
- `contents = [ app ]` uses the **same derivation** from Task 1 — `buildLayeredImage` walks its runtime closure and creates one layer per store path.
- **No `created = "now"`.** The default is `1970-01-01T00:00:01Z`. Setting it to `"now"` would break reproducibility (different images for each build); leaving it alone is what lets us get identical tarball hashes.

### 2.2 — Building and running

```bash
$ nix-build docker.nix
/nix/store/ljwm9dzvq9wl81224f4yiiwzi9zxl82l-nix-app.tar.gz

$ docker load < result
Loaded image: nix-app:latest

$ docker run --rm nix-app:latest
Built with Nix at compile time
Running at: 2026-04-23T22:04:34Z
```

### Image-size comparison

```bash
$ docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
test-app-docker:latest                                           1.25GB
traditional-app:latest                                           3.25MB
nix-app:latest                                                   11.7MB
```

| Image | How it's built | Size | Contents |
| ----- | -------------- | ---: | -------- |
| `test-app-docker` | `FROM golang:1.22` + `go build` | **1.25 GB** | Full Debian + Go toolchain + binary |
| `nix-app` (Nix `buildLayeredImage`) | Nix derivation + `contents = [app]` | **11.7 MB** | Go binary + glibc + tzdata (runtime closure only) |
| `traditional-app` (multistage `FROM scratch`) | Multistage Dockerfile | **3.25 MB** | Static binary only |

The traditional multistage image is the smallest because it uses `FROM scratch` + a fully static `CGO_ENABLED=0` binary. The Nix image is bigger because `buildGoModule` produces a dynamically-linked binary that pulls in `glibc` and `tzdata` at runtime. Both are drastically smaller than the naïve `FROM golang:1.22` build — but only the Nix image is also **reproducible** and **content-addressable** at the layer level.

### Reproducibility within the same Nix store (`--option build-repeat 2`)

```bash
$ nix-build docker.nix --option build-repeat 2
/nix/store/rd0jw19ipna2zw4dm25cqsbs3map1g3y-nix-app.tar.gz
$ sha256sum result
5aeb7a19e96db633361b90942262f9c4aca624929205a54ec0670d1fea20a1a8  result
```

`--option build-repeat 2` tells Nix to build the derivation twice and compare byte-for-byte; any divergence aborts with a `hash mismatch` error. The build succeeded silently, proving the image tarball is bit-for-bit reproducible when nixpkgs is held constant. (Across fresh containers with unpinned `<nixpkgs>`, the tarball hash varies — same caveat as Task 1.4, resolved by the Flake in the bonus.)

### Layer structure

```bash
$ docker history nix-app:latest
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
0cda19084c65   N/A                    12.3kB    store paths: ['/nix/store/fvh3qaiwr4nxgx3fvjb6xzr05wpldfz1-nix-app-customisation-layer']
<missing>      N/A                    1.71MB    store paths: ['/nix/store/b8pri17dfvzy8j0gh8wz50mp9zw3pvxn-nix-app-1.0.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/gn77r0iz2h4rhx44v1ak6i79dizm580a-tzdata-2025c']

$ docker history traditional-app
IMAGE          CREATED         CREATED BY                      SIZE      COMMENT
d15f771f9915   8 seconds ago   ENTRYPOINT ["/app"]             0B        buildkit.dockerfile.v0
<missing>      8 seconds ago   COPY /app/app /app # buildkit   2.01MB    buildkit.dockerfile.v0

$ docker history test-app-docker | head
IMAGE          CREATED          CREATED BY                                      SIZE
6b7809d3d32e   25 minutes ago   RUN /bin/sh -c go build -o app main.go …        31.4MB
<missing>      25 minutes ago   COPY main.go . # buildkit                       12.3kB
<missing>      25 minutes ago   WORKDIR /app                                    8.19kB
<missing>      14 months ago    WORKDIR /go                                     4.1kB
<missing>      14 months ago    RUN /bin/sh -c mkdir -p "$GOPATH/src"…          16.4kB
<missing>      14 months ago    COPY /target/ / # buildkit                      265MB
...
```

Note the structural difference:

- **Nix image:** `CREATED = N/A`, layers labelled by **Nix store path**. Each layer is a store path; identical closures across projects share layers via the binary cache.
- **Traditional image:** `CREATED = <timestamp>`, layers labelled by Dockerfile instruction. Timestamps are part of the layer hash, so "same Dockerfile, different day" gives a different image.

### Why Nix images are smaller and more reproducible

- **Closure-based contents.** `buildLayeredImage` includes *only* what the binary's runtime closure references — no `apt`, no `sh`, no package manager, no man pages.
- **One store path per layer.** Layers align with Nix store paths, which are content-addressable, so two images that share any runtime dependency can share that layer's download from the binary cache.
- **No build tools leak into the runtime image.** `go`, `gcc`, `binutils` are build-time inputs; they never make it into the runtime closure.

### Practical advantages of content-addressable Docker images

1. **Deduplication at the registry.** Two projects using the same `glibc` store path share that layer — the registry stores it once.
2. **Deterministic SBOM.** The image manifest *is* the bill of materials — every store path hash points at exact sources.
3. **Audit & rollback.** "What was in production on 2026-04-20?" is answered by a single `flake.lock` commit hash.
4. **Cache-friendly CI.** If CI rebuilds the image and the inputs match a cached revision, the build is replaced with a cache-hit download.

---

## Bonus — Modern Nix with Flakes (2 pts)

### B.1 — `flake.nix`

[flake.nix](lab11/app/flake.nix):

```nix
{
  description = "Reproducible Go app demonstrating Nix Flakes";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {

        packages.default = pkgs.buildGoModule {
          pname = "nix-app";
          version = "1.0.0";
          src = ./.;
          vendorHash = null;
        };

        packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "nix-app";
          tag = "latest";
          contents = [ self.packages.${system}.default ];
          config.Cmd = [ "/bin/app" ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.go pkgs.gopls pkgs.gotools ];
          shellHook = ''
            echo "Nix dev shell ready — Go $(go version)"
          '';
        };
      });
}
```

**Why this shape?**

- `inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11"` pins nixpkgs to a named release branch; the first `nix build` writes the exact git revision into `flake.lock`, which is what actually guarantees reproducibility.
- `flake-utils.lib.eachDefaultSystem` generates `packages.x86_64-linux.*`, `packages.aarch64-linux.*`, etc. without duplication.
- Three outputs in one file: the binary, the Docker image, and a dev shell.

### B.2 — `flake.lock` (excerpt)

[flake.lock](lab11/app/flake.lock) — generated by `nix flake update`:

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1720535198,
        "narHash": "sha256-zwVvxrdIzralnSbcpghA92tWu2DV2lwv89xZc8MTrbg=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "205fd4226592cc83fd4c0885a3e4c9c400efabb5",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-23.11",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    ...
  },
  "version": 7
}
```

`rev: 205fd42…` is the exact nixpkgs commit this project is pinned to. Anyone cloning this repo builds against that revision regardless of what `nixos-23.11` points at months later.

### B.3 — Flake build output

```bash
$ nix --extra-experimental-features 'nix-command flakes' flake show
git+file:///tmp/build-flake
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        ├───default: package 'nix-app-1.0.0'
        └───dockerImage: package 'nix-app.tar.gz'

$ nix build --print-out-paths
/nix/store/xwfc810n44sq9xplp38bszwrkay99605-nix-app-1.0.0
$ ./result/bin/app
Built with Nix at compile time
Running at: 2026-04-23T22:18:13Z
$ sha256sum result/bin/app
b262670de9c1e4afe2324632e178bc2d0bc5c8c2a34bdfe813e870f4e9dab7b9  result/bin/app
```

### Proof that builds are identical across invocations

The whole point of Flakes. Run in two independent fresh `nixos/nix` containers, each cloning the source, `git init`-ing, and running `nix build`:

| Invocation | Store path | Binary SHA-256 |
| ---------- | ---------- | -------------- |
| Container 1 | `/nix/store/xwfc810n44sq9xplp38bszwrkay99605-nix-app-1.0.0` | `b262670de9c1e4afe2324632e178bc2d0bc5c8c2a34bdfe813e870f4e9dab7b9` |
| Container 2 | `/nix/store/xwfc810n44sq9xplp38bszwrkay99605-nix-app-1.0.0` | `b262670de9c1e4afe2324632e178bc2d0bc5c8c2a34bdfe813e870f4e9dab7b9` |

**Store path AND binary hash are identical.** Contrast with Task 1.4 where the store paths diverged because `import <nixpkgs>` was unpinned. This is the whole value proposition of Flakes made concrete: once `flake.lock` exists, the closure is frozen.

### Dev shell

```bash
$ nix develop
Nix dev shell ready — Go go version go1.21.11 linux/amd64
$ which go
/nix/store/nnh57s7m672k6snkanhz1kb18skwjpbg-go-1.21.11/bin/go
$ which gopls
/nix/store/…-gopls-0.14.2/bin/gopls
```

### Why this beats traditional dev setups

- **Zero-install onboarding.** `nix develop` drops everyone into the same Go toolchain, language server, and `gotools` set — no README saying "install Go 1.21, then install gopls, then…".
- **Version-locked per project.** Two projects on the same laptop can depend on different Go versions without `gvm`/`asdf`.
- **Ephemeral.** Leave the shell, the tools aren't on your `$PATH` anymore. Nothing is globally installed.
- **Same primitives as CI.** The dev shell and the CI build both resolve through the same `flake.lock`; "works on my machine" becomes "works with this lock file."

### How Flakes improve on traditional Nix

| Concern | `default.nix` / channels | Flakes |
| ------- | ------------------------ | ------ |
| nixpkgs version | Comes from user's `NIX_PATH` / channel subscription | Pinned in `flake.lock` per project |
| Dependency locking | Ad-hoc (`niv`, `npins`, manual `builtins.fetchTarball` with a `sha256`) | Built in |
| Project discovery | Convention (`default.nix`, `shell.nix`) | Standardised outputs schema (`packages`, `devShells`, `apps`, `nixosConfigurations`, …) |
| Sharing | `nix-build '<nixpkgs>' -A ...` depending on user setup | `nix build github:owner/repo#default` works identically everywhere |
| Purity | Can reach outside the project via `<nixpkgs>` | `--pure-eval` by default, inputs must be declared |
| Cross-platform | Manual `system` handling | `eachDefaultSystem` handles it in one line |

The ergonomic win is real: `flake.lock` + `nix build` is to Nix what `package-lock.json` + `npm ci` was to npm, except the reproducibility guarantee is actual instead of aspirational.

---

## Reflection — what I took away

1. **Reproducibility ≠ determinism at runtime.** The binary's `time.Now()` output changes every execution; the binary *itself* is bit-identical. Nix guarantees the former, not the latter.
2. **`import <nixpkgs>` is a footgun.** Task 1.4 unintentionally demonstrated it — two fresh containers built identical *binaries* but produced different *store paths* because each container resolved the channel independently. Flakes turn this from a landmine into a lock file.
3. **`dockerTools` is the cleanest way to ship Docker images I've used.** No Dockerfile, no multistage incantation, no `.dockerignore` — the runtime closure of the derivation *is* the image contents.
4. **Content-addressable layers + `cache.nixos.org` are the unsung superpower.** Roughly 100 MB of toolchain downloaded on the first build was already present on the binary cache; nothing was compiled locally. That's the same mechanism that lets teams share build artefacts across CI, dev laptops, and production without a private registry.
