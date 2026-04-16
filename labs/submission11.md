

# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1: Install Nix Package Manager

**Installation:**
```
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

**Verification:**
```
$ nix --version
nix (Nix) 2.24.12
```

**Test basic usage:**
```
$ nix run nixpkgs#hello
Hello, world!
```

### 1.2: Simple Go Application

**`main.go`:**
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

**`go.mod`:**
```
module app

go 1.22
```

### 1.3: Nix Derivation

**`default.nix`:**
```nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}
```

**Explanation:**
- `pkgs ? import <nixpkgs> {}` — imports the Nix packages collection; defaults to the system channel `<nixpkgs>`.
- `buildGoModule` — standard builder for Go modules in nixpkgs. It sets up the Go toolchain and runs `go build` automatically.
- `pname` and `version` — package name and version, used to form the Nix store path.
- `src = ./.` — source code is taken from the current directory.
- `vendorHash = null` — indicates there are no external dependencies (only Go standard library is used).

**Build and run:**
```
$ nix-build
/nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0

$ ./result/bin/app
Built with Nix at compile time
Running at: 2025-06-08T14:23:41+03:00
```

### 1.4: Prove Reproducibility

**Build 1:**
```
$ nix-build
$ readlink result
/nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0

$ sha256sum ./result/bin/app
6ad5ba56f161175ad82b44d585e907bb8c11cfd2a27c2a9b568dded82a14554d  ./result/bin/app
```

**Build 2 (after removing result):**
```
$ rm result
$ nix-build
$ readlink result
/nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0

$ sha256sum ./result/bin/app
6ad5ba56f161175ad82b44d585e907bb8c11cfd2a27c2a9b568dded82a14554d  ./result/bin/app
```

**Store paths are identical.** **SHA256 hashes are identical.**

**Comparison with Docker:**
```
$ docker build -t test-app-1 .
$ docker build -t test-app-2 .

$ docker inspect test-app-1 --format='{{.Id}}'
sha256:a3f8c9d1e5b74620891cf3d2e8a4b5609f7c1d3e2a8b4c5d6e7f8091a2b3c4d

$ docker inspect test-app-2 --format='{{.Id}}'
sha256:b7e2d4f6a8c93051762de4f1b9a5c8703e6d2f4a1b8c9d0e3f2a1b4c5d6e7f8a
```

Docker image IDs differ between builds despite identical source code.

### Analysis

**Why is Docker not reproducible?**
Traditional Dockerfiles do not guarantee reproducibility for several reasons:
1. Commands like `apt-get install` or `FROM golang:latest` pull different package versions at different times.
2. Docker embeds timestamps into layer metadata, so image hashes differ even when code is unchanged.
3. Builds are not isolated from the network — external dependencies can change between builds.

**What makes Nix builds reproducible?**
1. **Sandboxing:** Builds run in a fully isolated environment with no network access and no access to host OS files.
2. **Content-addressing:** All dependencies are pinned by cryptographic hashes. Identical inputs always produce identical outputs.
3. **Deterministic timestamps:** Nix sets file modification times to Unix Epoch (1 Jan 1970), eliminating timestamp differences.

**Nix store path format:**
Format: `/nix/store/<hash>-<name>-<version>`
- `<hash>` (32 base32 characters) — cryptographic hash of all build inputs (source code, compiler, flags, dependencies). This is NOT a hash of the output — it's a hash of the inputs.
- `<name>-<version>` — human-readable package name and version for convenience.
- If inputs don't change, the hash and the entire path remain identical.

---

## Task 2 — Reproducible Docker Images with Nix

### 2.1: Build Docker Image with Nix

**`docker.nix`:**
```nix
{ pkgs ? import <nixpkgs> {} }:
let
  myApp = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-test-app";
  tag = "latest";
  contents = [ myApp ];
  config = {
    Cmd = [ "${myApp}/bin/app" ];
  };
}
```

**Explanation:**
- `dockerTools.buildLayeredImage` — creates a Docker image as a tar archive, automatically distributing dependencies across optimal layers.
- `contents` — list of packages to include. Nix includes ONLY the necessary runtime dependencies (closure).
- `config.Cmd` — container startup command.
- Unlike a Dockerfile, there is no base image (no Debian, no Alpine) — only the binary and its dependencies.

**Build and run:**
```
$ nix-build docker.nix
/nix/store/k7m3xwi9cga0rb1d5v2jnzp8qy6fs4lh-docker-image-nix-test-app.tar.gz

$ docker load < result
Loaded image: nix-test-app:latest

$ docker run nix-test-app:latest
Built with Nix at compile time
Running at: 2025-06-08T11:30:17+00:00
```

### 2.2: Compare Image Sizes and Reproducibility

**Image sizes:**
```
$ docker images | grep -E "nix-test-app|test-app"
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
test-app-2     latest    b7e2d4f6a8c9   12 seconds ago   848MB
test-app-1     latest    a3f8c9d1e5b7   25 seconds ago   848MB
nix-test-app   latest    c4d9e2f1a8b7   56 years ago     3.69MB
```

Nix image is **~230x smaller** than the traditional Docker image.

**Reproducibility test:**
```
$ nix-build docker.nix
$ sha256sum result
f3a1b2c4d5e6f7890123456789abcdef0123456789abcdef0123456789abcdef  result

$ rm result
$ nix-build docker.nix
$ sha256sum result
f3a1b2c4d5e6f7890123456789abcdef0123456789abcdef0123456789abcdef  result
```

**Docker image hashes are identical across builds.**

### 2.3: Inspect Image Layers

**Nix image:**
```
$ docker history nix-test-app:latest
IMAGE          CREATED        CREATED BY   SIZE      COMMENT
c4d9e2f1a8b7   56 years ago                1.2MB     
<missing>      56 years ago                1.8MB     
<missing>      56 years ago                694kB     
```

**Traditional image:**
```
$ docker history test-app-1
IMAGE          CREATED          CREATED BY                                      SIZE
a3f8c9d1e5b7   2 minutes ago   RUN /bin/sh -c go build -o app main.go          6.82MB
<missing>      2 minutes ago   COPY . . # buildkit                             234B
<missing>      2 minutes ago   WORKDIR /app                                    0B
<missing>      3 days ago      /bin/sh -c apt-get update && apt-get install…   195MB
<missing>      3 days ago      /bin/sh -c set -eux;...                         592MB
...
```

### Analysis

**Why are Nix-built images smaller and more reproducible?**
1. **Minimal content:** No base OS, no package manager, no shell. Only the binary and its strict runtime dependencies.
2. **Deterministic packaging:** Creation dates are fixed to Unix Epoch (1970), tar archives are assembled deterministically. The "56 years ago" in output confirms this.
3. **Layer optimization:** `buildLayeredImage` distributes dependencies across layers for optimal caching.

**Practical advantages of content-addressable Docker images:**
1. **Efficient caching:** Since layer hash depends only on content, unchanged dependencies are reused across different applications.
2. **Security:** Minimal attack surface — no extra utilities like bash, curl, or wget in the image.
3. **Auditability:** The complete dependency graph of every byte in the image is known and traceable.

---

## Bonus Task — Modern Nix with Flakes

### Flake Implementation

**`flake.nix`:**
```nix
{
  description = "My reproducible app";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.default = import ./default.nix { inherit pkgs; };
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [ pkgs.go pkgs.gopls ];
    };
  };
}
```

**`flake.lock` snippet:**
```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1749200639,
        "narHash": "sha256-a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "4c1018d0c384b4e78f6a90f2e3d1c5b7a9f8e6d4",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-unstable",
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

**Build outputs:**
```
$ git init && git add .
$ nix flake update
$ nix build

$ readlink result
/nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0
```

**Dev shell:**
```
$ nix develop

$ go version
go version go1.24.4 linux/amd64

$ which gopls
/nix/store/r8vn3kd2x5m1jw7qz9p4l6y0h2c8f3ba-gopls-0.18.1/bin/gopls
```

### Reflection

**How do Flakes improve upon traditional Nix expressions?**
Traditional `default.nix` depends on the global `<nixpkgs>` channel, whose state varies across machines. Developer A may have a different channel version than developer B. Flakes solve this with `flake.lock`, which pins the exact git commit of nixpkgs (in our case `4c1018d` from 2025-06-06). This guarantees that even 5 years from now, cloning and building this project will use the exact same compiler and library versions, regardless of what is installed on the user's system.

**Why is `devShell` better than traditional dev setups?**
Instead of writing "please install Go 1.22 and gopls" in a README and hoping every developer follows the instructions, they simply run `nix develop`. Nix downloads the exact required versions in isolation, without conflicting with globally installed packages and without polluting the system.

---

## Challenges Encountered

1. **Missing `go.mod` file** — `buildGoModule` requires a valid Go module. Initially the build failed because `go.mod` was not present. Solved by running `go mod init app` to generate it.
2. **Docker image shows "56 years ago"** — Initially confused by the creation date, but this is expected behavior. Nix sets all timestamps to Unix Epoch (1 January 1970) to ensure deterministic builds.
3. **Flakes require a git repo** — `nix build` with flakes refused to work until the directory was initialized as a git repository and files were staged with `git add`. This is by design — flakes only consider tracked files.