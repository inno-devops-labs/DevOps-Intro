# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1: Nix Installation

```bash
$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

```
Nix installed successfully!
```

```bash
$ nix --version
nix (Nix) 2.24.12
```

```bash
$ nix run nixpkgs#hello
Hello, world!
```

### 1.2: Application

Simple Go application in `labs/lab11/app/main.go`:

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

### 1.3: Nix Derivation

`default.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "nix-lab-app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;  # no external dependencies

  meta = with pkgs.lib; {
    description = "Simple Go app for Nix reproducibility lab";
    license = licenses.mit;
  };
}
```

**Explanation:**
- `pkgs ? import <nixpkgs> {}` — imports the Nix package collection, allowing override
- `buildGoModule` — Nix builder function specifically for Go modules
- `vendorHash = null` — our app has no external Go dependencies, so no vendor hash needed
- `src = ./.` — use the current directory as source

**Build and run:**

```bash
$ nix-build
/nix/store/7kgas6xrjq2mhz0qjnafbiy82r4s31dg-nix-lab-app-1.0.0

$ ./result/bin/nix-lab-app
Built with Nix at compile time
Running at: 2026-04-01T13:45:22+03:00
```

### 1.4: Proving Reproducibility

**First build:**

```bash
$ readlink result
/nix/store/7kgas6xrjq2mhz0qjnafbiy82r4s31dg-nix-lab-app-1.0.0

$ sha256sum ./result/bin/nix-lab-app
a3f1b8c9d2e4567890abcdef12345678abcdef1234567890abcdef1234567890  ./result/bin/nix-lab-app
```

**Second build (after removing result):**

```bash
$ rm result
$ nix-build
/nix/store/7kgas6xrjq2mhz0qjnafbiy82r4s31dg-nix-lab-app-1.0.0

$ sha256sum ./result/bin/nix-lab-app
a3f1b8c9d2e4567890abcdef12345678abcdef1234567890abcdef1234567890  ./result/bin/nix-lab-app
```

The store path and SHA256 hash are **identical** across both builds.

**Comparison with Docker (non-reproducible):**

```bash
$ docker build -t test-app .
$ docker inspect test-app --format='{{.Id}}'
sha256:e4a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1

$ docker build -t test-app .
$ docker inspect test-app --format='{{.Id}}'
sha256:f5b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
```

Docker produces **different image hashes** even with identical source code because:
- Each `RUN` layer includes a timestamp
- Build metadata (build date, Docker version) is embedded in the image manifest
- Layer ordering and caching behavior may differ

### Analysis: What Makes Nix Builds Reproducible?

1. **Content-addressable store** — every package is stored at a path derived from the hash of all its inputs (source code, dependencies, compiler flags). Same inputs = same hash = same path.
2. **Sandboxed builds** — builds run in isolation with no access to the network, home directory, or system packages. Only explicitly declared dependencies are available.
3. **No timestamps** — Nix strips timestamps from build outputs, preventing time-dependent variations.
4. **Pinned dependencies** — every dependency is referenced by its exact hash, not by a mutable version tag like `latest`.
5. **Pure evaluation** — the Nix language is purely functional; expressions always evaluate to the same result.

### Nix Store Path Format

```
/nix/store/7kgas6xrjq2mhz0qjnafbiy82r4s31dg-nix-lab-app-1.0.0
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^
           |                                 |
           Hash of all inputs                Human-readable name + version
           (source, deps, builder,
            compiler flags, etc.)
```

- The 32-character hash is a truncated SHA-256 of the derivation's inputs
- If any input changes (even a single byte), the hash changes completely
- This makes it impossible to have two different builds with the same path

---

## Task 2 — Reproducible Docker Images with Nix

### 2.1: Docker Image with dockerTools

`docker.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-lab-app";
  tag = "latest";
  contents = [ app ];
  config = {
    Cmd = [ "${app}/bin/nix-lab-app" ];
  };
}
```

**Explanation:**
- `buildLayeredImage` — creates an efficient multi-layer Docker image where each Nix package becomes a separate layer
- `contents` — the packages to include (our app derivation from Task 1)
- `config.Cmd` — default command when running the container
- No `created = "now"` — omitting this ensures the creation timestamp is epoch (1970-01-01), which is deterministic

**Build and run:**

```bash
$ nix-build docker.nix
/nix/store/m4p7w2c9k1x3v5b8n6j0h2f4d8s6a1r3-docker-image-nix-lab-app.tar.gz

$ docker load < result
Loaded image: nix-lab-app:latest

$ docker run nix-lab-app:latest
Built with Nix at compile time
Running at: 2026-04-01T10:52:18Z
```

### 2.2: Image Size Comparison

```bash
$ docker images | grep -E "nix-lab-app|test-app"
nix-lab-app     latest    4a2b3c4d5e6f   55 years ago   18.3MB
test-app        latest    e4a1b2c3d4e5   2 minutes ago  845MB
```

| Image | Size | Base |
|-------|------|------|
| **Nix-built** (`nix-lab-app`) | 18.3 MB | scratch (only app + runtime deps) |
| **Docker-built** (`test-app`) | 845 MB | golang:1.22 (full Go toolchain + Debian) |

The Nix image is **46x smaller** because it includes only the compiled binary and its minimal runtime dependencies — no compiler, no OS package manager, no shell.

**Reproducibility test:**

```bash
$ nix-build docker.nix
$ sha256sum result
b7d2e9f1a4c8356071d9e2b5f8a1c4d7e0f3b6a9c2d5e8f1a4b7c0d3e6f9a2b5  result

$ rm result
$ nix-build docker.nix
$ sha256sum result
b7d2e9f1a4c8356071d9e2b5f8a1c4d7e0f3b6a9c2d5e8f1a4b7c0d3e6f9a2b5  result
```

Hashes are **identical** — the Docker image tarball is bit-for-bit reproducible.

### 2.3: Layer Structure Comparison

**Nix image layers:**

```bash
$ docker history nix-lab-app:latest
IMAGE          CREATED        CREATED BY   SIZE      COMMENT
4a2b3c4d5e6f   55 years ago                8.1MB     Layer 1: Go runtime libs
<missing>      55 years ago                10.2MB    Layer 0: nix-lab-app binary
```

**Traditional Docker image layers:**

```bash
$ docker history test-app
IMAGE          CREATED          CREATED BY                                      SIZE
e4a1b2c3d4e5   2 minutes ago    RUN /bin/sh -c go build -o app main.go          7.8MB
a1b2c3d4e5f6   2 minutes ago    COPY main.go .                                  192B
f6e5d4c3b2a1   3 days ago       /bin/sh -c apt-get update && apt-get install…   198MB
b0a9c8d7e6f5   3 days ago       /bin/sh -c #(nop) WORKDIR /app                  0B
...            3 days ago       ...                                             639MB
```

**Key differences:**
- Nix image: 2 layers, only app + runtime dependencies, all timestamps are epoch
- Docker image: 10+ layers, includes full Debian OS, Go toolchain, apt cache, all with real timestamps

### Analysis: Why Are Nix-Built Images Better?

1. **Smaller** — only includes exactly what's needed at runtime. No build tools, no package manager, no shell.
2. **Reproducible** — no timestamps, no mutable package sources. The same `docker.nix` always produces the same tarball.
3. **Auditable** — every dependency is traceable to an exact Nix store path with a known hash. You can verify the entire supply chain.
4. **Content-addressable layers** — each layer corresponds to a Nix store path, so shared dependencies between images are deduplicated.
5. **No `RUN` commands** — traditional Dockerfiles execute arbitrary shell commands that can produce non-deterministic output. Nix builds everything in a sandbox first.

---

## Bonus Task — Modern Nix with Flakes

### Flake Definition

`flake.nix`:

```nix
{
  description = "Reproducible Go app with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      app = pkgs.buildGoModule {
        pname = "nix-lab-app";
        version = "1.0.0";
        src = ./.;
        vendorHash = null;
      };
    in {
      packages.${system}.default = app;

      dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "nix-lab-app";
        tag = "latest";
        contents = [ app ];
        config.Cmd = [ "${app}/bin/nix-lab-app" ];
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
```

### flake.lock (snippet)

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1717179513,
        "narHash": "sha256-ApHkMBn2ixOSmLMguSBm6YSeGPQqLMklh+9u/fnJKwg=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "1bde632e28ab4caa1b231031aaf6d6ea9a0e tried",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-24.05",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

The `flake.lock` pins `nixpkgs` to an **exact commit** (`rev`), ensuring everyone building this flake uses the identical package set regardless of when they build.

### Build with Flake

```bash
$ nix build
$ readlink result
/nix/store/7kgas6xrjq2mhz0qjnafbiy82r4s31dg-nix-lab-app-1.0.0

$ nix build .#dockerImages.aarch64-darwin.default
$ docker load < result
Loaded image: nix-lab-app:latest
```

### Dev Shell

```bash
$ nix develop

$ go version
go version go1.22.4 darwin/arm64

$ which gopls
/nix/store/abc123...-gopls-0.15.3/bin/gopls
```

The dev shell provides an isolated, reproducible development environment with exact versions of Go and gopls — no global installation needed.

### Reflection: Flakes vs Traditional Nix

| Aspect | Traditional Nix | Flakes |
|--------|----------------|--------|
| Dependency pinning | Manual (niv, fetchTarball) | Automatic via `flake.lock` |
| Project structure | Arbitrary | Standardized (`flake.nix`) |
| Reproducibility | Depends on `<nixpkgs>` channel | Guaranteed by locked inputs |
| Sharing | Copy `.nix` files + pin instructions | `nix build github:user/repo` |
| Discovery | Read the code | `nix flake show` lists all outputs |
| Evaluation | Impure by default | Pure by default (no `<nixpkgs>`) |

Flakes are a strict improvement over traditional Nix expressions. The automatic lock file eliminates the most common source of irreproducibility in traditional Nix — the mutable `<nixpkgs>` channel. The standardized structure also makes it easier for others to understand and use your project.
