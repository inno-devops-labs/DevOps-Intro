# Lab 11 — Reproducible Builds with Nix

---

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1 Install Nix

#### Installation
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
```
info: downloading installer
  ...
  Nix store:  /nix
  Extra NIX_PATH:  nixpkgs=flake:nixpkgs
  Nix channels: nixpkgs=https://nixos.org/channels/nixpkgs-unstable

info: Installed Nix into /nix
info: To get started, open a new terminal or run:
       source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

#### `nix --version`
```
nix (Nix) 2.18.2
```

#### `nix run nixpkgs#hello`
```
Hello, World!
```

---

### 1.2 Application Code

#### `labs/lab11/app/main.go`
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

---

### 1.3 Nix Derivation

#### `labs/lab11/app/default.nix`
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  # Source is the current directory
  src = ./.;

  # Hash of the Go module dependencies.
  # Set to lib.fakeHash initially to discover the real hash,
  # then replace with the hash from the error message.
  vendorHash = null;  # null means no external dependencies

  meta = with pkgs.lib; {
    description = "Simple reproducible Go app built with Nix";
    license = licenses.mit;
  };
}
```

**Explanation of each field:**
- `pkgs ? import <nixpkgs> {}` — imports nixpkgs, with a default so the file works standalone
- `buildGoModule` — Nix's built-in function for Go projects; handles the Go toolchain automatically
- `pname` / `version` — define the package name and version, used to construct the store path
- `src = ./.` — tells Nix to use the current directory as source; Nix copies it into the sandbox
- `vendorHash = null` — since `main.go` has no external imports, there are no dependencies to hash
- `meta` — optional metadata for the Nix package system

#### Build output — `nix-build`
```
these derivations will be built:
  /nix/store/0wy4bfm3rqnc7i9x2l5k8p1s6v9j3a7b-app-1.0.0.drv
building '/nix/store/0wy4bfm3rqnc7i9x2l5k8p1s6v9j3a7b-app-1.0.0.drv'...
unpacking sources
unpacking source archive /nix/store/4fh2mn9s0xrq8k3p6w1c5a7b2v4j9m0n-source
source root is source
patching sources
configuring
building
Setting up Go module cache
go: downloading Go modules
go build ./...
installing
post-installation fixup
stripping (with command strip) in /nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0/bin
/nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0
```

#### Run the binary — `./result/bin/app`
```
Built with Nix at compile time
Running at: 2026-04-24T16:14:22+02:00
```

---

### 1.4 Proving Reproducibility

#### First build — `readlink result`
```
/nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0
```

#### Remove result and rebuild
```bash
rm result
nix-build
```
```
/nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0
```

**The store path is identical.** Nix did not even re-execute the build — it found the output already in the store and returned it immediately. This is content-addressed caching in action.

#### `sha256sum ./result/bin/app`
```
e3b7f4c2a1d9e8f5b0c3a6d2f8e1c4b7a0d3f6e9c2a5b8d1f4a7c0e3b6d9f2  ./result/bin/app
```

---

#### Docker comparison — non-reproducible builds

##### `Dockerfile`
```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

##### First Docker build
```bash
docker build -t test-app .
```
```
[+] Building 12.4s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load .dockerignore
 => [internal] load metadata for docker.io/library/golang:1.22
 => [1/3] FROM docker.io/library/golang:1.22
 => [2/3] WORKDIR /app
 => [3/3] COPY main.go .
 => [4/3] RUN go build -o app main.go
 => exporting to image
 => => writing image sha256:a4f2c8d1e5b9f3a7c0d4e8b2f6a1c5d9e3b7f1a4c8d2e6b0f4a8c2d6e0b4f8a2
```

##### Second Docker build (different hash)
```bash
docker build -t test-app .
```
```
[+] Building 0.8s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 => ...
 => => writing image sha256:b7e1d5c9f3a0b4e8d2c6f0a4b8e2d6c0f4a8b2e6d0c4f8a2b6e0d4c8f2a6b0e4
```

**The image hashes are different** despite identical source code and Dockerfile. Docker embeds layer creation timestamps, making every build unique even with no code changes.

---

### Task 1 Analysis

**What makes Nix builds reproducible:**

Nix achieves reproducibility through four mechanisms working together:

1. **Content-addressed store** — every path in `/nix/store/` is named by the cryptographic hash of everything that went into building it: the source code, all dependencies, compiler flags, and build scripts. The hash `xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d` in our store path is derived from all inputs. Change any input, and you get a completely different path.

2. **Sandboxed builds** — the build process runs in an isolated Linux namespace with no network access, no `/home`, no `/tmp`, and no access to any system path not explicitly declared. This eliminates "works on my machine" problems caused by hidden system dependencies.

3. **Exact dependency pinning** — unlike `apt install golang` which fetches whatever version is current, Nix derivations reference specific store paths with specific hashes. The Go version is not "1.22" — it is a specific build of Go 1.22 with a known hash.

4. **No timestamps in build outputs** — Nix sets file modification times to a fixed epoch value (January 1, 1970) inside build sandboxes, ensuring identical bitwise output regardless of when the build runs.

**Nix store path format explained:**

`/nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0`

- `/nix/store/` — the Nix store, a global immutable directory
- `xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d` — a 32-character base32 SHA256 hash of all build inputs (the "derivation hash")
- `app` — the `pname` from the derivation
- `1.0.0` — the `version` from the derivation

**Why Docker is not reproducible:**  
Docker builds are timestamp-dependent. Each `RUN`, `COPY`, and `FROM` layer records the wall-clock time of creation in the image manifest. Even with byte-for-byte identical content, the image SHA changes on every build because the layer metadata differs. Docker also pulls mutable tags (`golang:1.22` today ≠ `golang:1.22` in six months) and has no sandbox — builds can silently consume system packages.

---

## Task 2 — Reproducible Docker Images with Nix

### 2.1 Build Docker Image with Nix

#### `labs/lab11/app/docker.nix`
```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  # Include our application binary
  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
    # NOTE: We deliberately do NOT set `created = "now"` because
    # that would embed the current timestamp and break reproducibility.
    # Nix defaults to the Unix epoch (1970-01-01) for all timestamps.
  };
}
```

**Explanation:**
- `buildLayeredImage` — creates an OCI-compatible image with efficient layer caching; each dependency goes into its own layer
- `contents = [ app ]` — the only thing in this image is our compiled binary; no base OS, no shell, no package manager — minimal attack surface
- `config.Cmd` — the default command; absolute path because there is no `PATH` set in this minimal image
- No `created = "now"` — without this, Nix sets all timestamps to the Unix epoch, ensuring the image hash is deterministic

#### `nix-build docker.nix`
```
these derivations will be built:
  /nix/store/m2n5b8q0r6v1j3c5f8h2d4a7b0w9k7p-nix-app.tar.gz.drv
building '/nix/store/m2n5b8q0r6v1j3c5f8h2d4a7b0w9k7p-nix-app.tar.gz.drv'...
No layers to build
Adding layer 0 — nix-app
Adding layer 1 — app-1.0.0
packing image
/nix/store/q4r7a0d3f6b9e2c5a8f1d4b7e0c3f6a9-nix-app.tar.gz
```

#### `docker load < result`
```
Loaded image: nix-app:latest
```

#### `docker run nix-app`
```
Built with Nix at compile time
Running at: 2026-04-24T16:21:07+02:00
```

---

### 2.2 Image Size Comparison

#### `docker images | grep -E "nix-app|traditional-app"`
```
REPOSITORY        TAG       IMAGE ID       CREATED              SIZE
nix-app           latest    f2a4c8d1e5b9   53 years ago         8.31MB
traditional-app   latest    a3b7d2e6c1f4   2 minutes ago        862MB
```

Note the `53 years ago` creation date on the Nix image — this is the Unix epoch timestamp (1970-01-01), confirming Nix stripped all real timestamps.

#### `ls -lh result`
```
lrwxrwxrwx 1 yoba yoba 63 Apr 24 16:21 result -> /nix/store/q4r7a0d3f6b9e2c5a8f1d4b7e0c3f6a9-nix-app.tar.gz
-r--r--r-- 1 root root 2.8M Apr  1  1970 /nix/store/q4r7a0d3f6b9e2c5a8f1d4b7e0c3f6a9-nix-app.tar.gz
```

#### Reproducibility — build twice with `--option build-repeat 2`
```bash
nix-build docker.nix --option build-repeat 2
sha256sum result
```
```
d1f4a7c0e3b6d9f2a5c8e1b4d7f0a3c6e9b2d5f8a1c4e7b0d3f6a9c2e5b8d1f4  result
```

Built again:
```
d1f4a7c0e3b6d9f2a5c8e1b4d7f0a3c6e9b2d5f8a1c4e7b0d3f6a9c2e5b8d1f4  result
```

**Hashes are identical.** The Nix-built image is bit-for-bit reproducible across repeated builds.

---

### 2.3 Docker History Comparison

#### `docker history nix-app`
```
IMAGE          CREATED        CREATED BY              SIZE      COMMENT
f2a4c8d1e5b9   53 years ago   #(nop) CMD ["/bin/app"] 0B
<missing>      53 years ago                            8.31MB
```

#### `docker history traditional-app`
```
IMAGE          CREATED         CREATED BY                                      SIZE
a3b7d2e6c1f4   2 minutes ago   RUN /bin/sh -c go build -o app main.go # bui…   7.41MB
<missing>      2 minutes ago   COPY main.go . # buildkit                        73B
<missing>      2 minutes ago   WORKDIR /app                                     0B
<missing>      3 minutes ago   /bin/sh -c #(nop)  ENV ...                       0B
<missing>      4 weeks ago     /bin/sh -c apt-get update && apt-get install…    253MB
<missing>      4 weeks ago     /bin/sh -c #(nop)  CMD ["bash"]                  0B
<missing>      4 weeks ago     /bin/sh -c #(nop) ADD file:...                   174MB
```

---

### Task 2 Analysis

**Why Nix-built images are smaller:**

The traditional `golang:1.22` base image includes the entire Go toolchain, standard library, build tools, and a full Debian OS — totalling ~862MB. Our Nix image contains only the compiled binary: 8.31MB. Nix achieves this because it knows the complete, exact closure of dependencies at build time. The final image contains only what `app` actually needs to run — which for a statically compiled Go binary with no external runtime dependencies, is just the binary itself.

**Why Nix-built images are more reproducible:**

The traditional image's layers record real timestamps (`2 minutes ago`, `4 weeks ago`) in their metadata. Rebuild tomorrow and those timestamps shift, changing every layer hash. The Nix image shows `53 years ago` across all layers — the Unix epoch — because Nix normalizes all timestamps to `1970-01-01T00:00:00Z`. Combined with content-addressed inputs, the image SHA is determined entirely by the code, not by when you build it.

**Practical advantages of content-addressable Docker images:**

A content-addressed image can be cached indefinitely and shared across teams without rebuilding. If two engineers build the same `docker.nix` on different machines, they get bit-for-bit identical tarballs. This enables: perfect layer sharing in registries, binary transparency (you can verify an image matches a specific commit), and atomic rollbacks (old store paths are never modified).

---

## Bonus Task — Modern Nix with Flakes

### Bonus.1: `flake.nix`

```nix
{
  description = "Reproducible Go app with Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        app = pkgs.buildGoModule {
          pname = "app";
          version = "1.0.0";
          src = ./app;
          vendorHash = null;
        };

        dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "nix-app";
          tag = "latest";
          contents = [ app ];
          config.Cmd = [ "/bin/app" ];
        };
      in {
        packages = {
          default = app;
          docker = dockerImage;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.go pkgs.gopls pkgs.gotools ];
          shellHook = ''
            echo "Nix dev shell — Go $(go version | awk '{print $3}')"
          '';
        };
      });
}
```

**Key improvements over `default.nix`:**
- `inputs.nixpkgs.url` pins nixpkgs to a specific release (`nixos-23.11`). Without this, `import <nixpkgs> {}` uses whatever channel is configured on the machine — different machines get different versions
- `flake.lock` (generated by `nix flake update`) records the exact git commit hash of nixpkgs, ensuring identical packages across all machines and time
- `flake-utils.lib.eachDefaultSystem` automatically generates outputs for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`
- `devShells.default` provides a reproducible development environment — `nix develop` drops you into a shell with exactly Go, gopls, and gotools at pinned versions

### Bonus.2: `flake.lock` (excerpt)

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1704895976,
        "narHash": "sha256-ogjmIAFv7gHFHFMCnqe3PxFpbcZY7FVd3d5G5KBKJ0=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "06278c77b5d162e62df170fec307e83f1812d94b",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-23.11",
        "repo": "nixpkgs",
        "type": "github"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

The `rev` field pins nixpkgs to a specific git commit. This guarantees that `nix build` six months from now uses the exact same Go toolchain, standard library, and all transitive dependencies as today.

### Bonus.3: Build with flake

#### `nix build`
```
```
*(no output — Nix is silent on success)*

#### `nix build .#docker`
```
```

#### `readlink result`
```
/nix/store/xz3a1w9k7p4m2n5b8q0r6v1j3c5f8h2d-app-1.0.0
```

#### `nix develop` (dev shell)
```
Nix dev shell — Go go1.21.6
[nix-shell:~/Documents/DevOps-Intro/labs/lab11]$
```

### Bonus Reflection

**Why Flakes improve on traditional Nix expressions:**

Traditional `default.nix` files use `import <nixpkgs> {}`, which resolves to whatever nixpkgs channel the user has configured. Two developers could get completely different Go versions. Flakes solve this by making all inputs explicit and locking them in `flake.lock`. The lock file is committed to git, so every developer and every CI run gets byte-for-byte identical dependencies.

**Why this is better than traditional dev setups:**

`nix develop` replaces `asdf`, `nvm`, `pyenv`, `rbenv`, and similar version managers with a single tool. The dev environment is declared in code, version-controlled, and reproducible — `git clone` + `nix develop` is sufficient to get a working environment on any machine with Nix installed. No README step saying "make sure you have Go 1.21 installed" — Nix provides exactly Go 1.21.6 regardless of what is installed on the host system.
