# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1: Nix Installation

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

```
nix (Determinate Nix 3.17.3) 2.33.3
```

```bash
nix run nixpkgs#hello
# Hello, world!
```

The Determinate Systems installer was chosen because it enables Flakes by default. It automatically created an encrypted APFS volume for the Nix store, set up build users (UIDs 351–382), and configured the Nix daemon.

---

### 1.2: Application — `main.go`

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

Go was chosen because it compiles to a single static binary, making hash-based reproducibility verification straightforward.

---

### 1.3: Nix Derivation — `default.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0";
  src = ./.;
  vendorHash = null;
}
```

**Explanation:**

| Field | Meaning |
|-------|---------|
| `pkgs ? import <nixpkgs> {}` | Imports the Nix package set; `?` makes it overridable |
| `buildGoModule` | Nix helper that compiles Go modules in a sandboxed environment |
| `pname = "app"` | Package name, used to construct the store path |
| `version = "1.0"` | Combined with pname → derivation name `app-1.0` |
| `src = ./.` | Nix copies the source into the store before building — isolated from local changes |
| `vendorHash = null` | No external Go dependencies |

**First build failed** — `go.mod` was missing:

```
go: go.mod file not found in current directory or any parent directory
```

**Fix:**

```bash
nix shell nixpkgs#go
go mod init app
```

**Second build succeeded:**

```
/nix/store/xib6q2ilgmn3p0wyqn06ply6xiirl96c-app-1.0
```

**Running the binary:**

```
./result/bin/app
Built with Nix at compile time
Running at: 2026-04-16T20:12:46+03:00
```

---

### 1.4: Proof of Reproducibility

#### Store Path — Build 1

```bash
readlink result
# /nix/store/xib6q2ilgmn3p0wyqn06ply6xiirl96c-app-1.0
```

#### Store Path — Build 2 (after deleting symlink)

```bash
rm result
nix-build
readlink result
# /nix/store/xib6q2ilgmn3p0wyqn06ply6xiirl96c-app-1.0
```

**The store path is identical.** Same inputs → same content-addressed hash → same output path.

#### SHA256 of the Binary

```
shasum -a 256 ./result/bin/app
106ef8ef419a625f55283248af92b09421245fa1fdad51d83444d7c6480f428d  ./result/bin/app
```

#### Nix Store Path Format Explained

`/nix/store/xib6q2ilgmn3p0wyqn06ply6xiirl96c-app-1.0`

| Part | Meaning |
|------|---------|
| `/nix/store/` | Global immutable Nix store |
| `xib6q2ilgmn3p0wyqn06ply6xiirl96c` | SHA256 hash of ALL inputs: source, compiler, dependencies, flags |
| `app-1.0` | Human-readable name (`pname-version`) |

Any change to source, dependencies, or compiler produces a completely different hash.

---

### 1.5: Docker Comparison — Why Docker Is Not Reproducible

**Dockerfile:**

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

**Built three times with identical source:**

```bash
docker build -t test-app .
docker build --no-cache -t test-app-1 .
docker build --no-cache -t test-app-2 .
```

```
test-app-2   latest   a112d71f1a8d   4 seconds ago    1.25GB
test-app-1   latest   e76d342b0004   13 seconds ago   1.25GB
test-app     latest   e7414cde5405   38 minutes ago   1.25GB
```

**All three images have different hashes despite identical source code.**

#### Why Docker Fails at Reproducibility

1. **Timestamps in layers** — Docker embeds build time in each layer. Same content, different time = different hash.
2. **No input hashing** — Docker has no mechanism to hash the compiler, stdlib, and libc into the output identity.
3. **Package drift** — `FROM golang:1.22` may pull different patch versions over time.
4. **Build environment leakage** — Docker builds can access the network by default, introducing non-determinism.

#### What Makes Nix Reproducible

1. **Content-addressable store** — the store path IS the hash of inputs; same path = guaranteed identical binary.
2. **Sandboxed builds** — no network, no home directory, only declared dependencies are visible.
3. **Pinned dependencies** — every package has an exact version with a verified hash.
4. **No timestamps** — Nix sets mtimes to Unix epoch (`1970-01-01`).
5. **Pure functions** — a derivation is a pure function: same inputs always produce the same output.

---

## Task 2 — Reproducible Docker Images with Nix

### 2.1: `docker.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.buildGoModule {
    pname = "app";
    version = "1.0";
    src = ./.;
    vendorHash = null;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  contents = [ app pkgs.tzdata ];

  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
```

**Explanation:**

| Field | Meaning |
|-------|---------|
| `dockerTools.buildLayeredImage` | Nix built-in that produces an OCI-compatible tarball without Docker daemon |
| `contents = [ app pkgs.tzdata ]` | Only these two packages are in the image — no OS, no shell, no compiler |
| `Cmd = [ "${app}/bin/app" ]` | Full Nix store path to the binary — guarantees the exact binary is referenced |
| No `created = "now"` | Timestamp set to Unix epoch — preserves reproducibility |

**Build and load:**

```bash
nix-build docker.nix
docker load < result
# Loaded image: nix-app:latest
```

---

### 2.2: Image Size Comparison

```
docker images | grep -E "nix-app|traditional-app|test-app"

traditional-app    latest    94a8417195c1   15 hours ago    1.25GB
test-app-2         latest    a112d71f1a8d   15 hours ago    1.25GB
test-app-1         latest    e76d342b0004   15 hours ago    1.25GB
test-app           latest    e7414cde5405   15 hours ago    1.25GB
nix-app            latest    d455e6c23603   56 years ago    11.9MB
```

| Image | Size | Notes |
|-------|------|-------|
| `traditional-app` (Dockerfile) | 1.25 GB | Full Debian + Go toolchain |
| `nix-app` (Nix) | **11.9 MB** | Only app binary + tzdata |

Nix image is **~105x smaller.**

> **Note:** `nix-app` shows "56 years ago" because Nix sets the creation timestamp to Unix epoch (`1970-01-01`) intentionally — this is what makes the image hash reproducible across time.

---

### 2.3: Layer Structure Comparison

```
docker history nix-app:latest

IMAGE          CREATED   CREATED BY   SIZE      COMMENT
d455e6c23603   N/A                    8.19kB    store paths: ['/nix/store/xvyn376lqy25h7dlfhc1yck5p4v4wbym-nix-app-customisation-layer']
<missing>      N/A                    1.79MB    store paths: ['/nix/store/5qgrhsb53i574sgnypizybm0shps97r4-app-1.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/vfxb0ds1k2kisiql1vj65cff61yp0jbq-tzdata-2026a']
```

```
docker history traditional-app:latest

IMAGE          CREATED         CREATED BY                                      SIZE
94a8417195c1   15 hours ago    RUN /bin/sh -c go build -o app main.go          31.6MB
<missing>      15 hours ago    COPY main.go .                                  12.3kB
<missing>      15 hours ago    WORKDIR /app                                    8.19kB
<missing>      14 months ago   WORKDIR /go                                     4.1kB
<missing>      14 months ago   RUN /bin/sh -c mkdir -p "$GOPATH/src"...        16.4kB
<missing>      14 months ago   COPY /target/ /                                 263MB
<missing>      14 months ago   ENV GOLANG_VERSION=1.22.12                      0B
<missing>      2 years ago     RUN /bin/sh -c apt-get update...                248MB
<missing>      2 years ago     RUN /bin/sh -c apt-get update...                200MB
<missing>      2 years ago     RUN /bin/sh -c apt-get update...                52.4MB
<missing>      2 years ago     # debian.sh --arch 'arm64' out/ 'bookworm'...   155MB
```

**Key differences:**

| Property | Nix image | Traditional Dockerfile |
|----------|-----------|----------------------|
| Number of layers | 3 | 11 |
| Timestamps | All `N/A` (epoch) | Real timestamps — different every build |
| Layer contents | Exact Nix store paths | Opaque shell commands |
| Base OS | None | Full Debian (~655 MB) |
| Total size | 11.9 MB | 1.25 GB |
| Reproducible hash | ✅ | ❌ |

---

### 2.4: Reproducibility Proof for Docker Image

```bash
shasum -a 256 result
# 9b77192f82d7422204009f36c2406eb236bb4ca5ad1ba24b9208f8dc73758f78  result

rm result
nix-build docker.nix
shasum -a 256 result
# 9b77192f82d7422204009f36c2406eb236bb4ca5ad1ba24b9208f8dc73758f78  result
```

**Both builds produce an identical tarball.** This is impossible with a traditional Dockerfile due to embedded timestamps.

---

### 2.5: Note on `exec format error`

When running `docker run nix-app:latest` on macOS with Apple Silicon (aarch64-darwin):

```
exec /nix/store/.../bin/app: exec format error
```

**Root cause:** The Nix build runs natively on `aarch64-darwin` (macOS). The resulting binary is compiled for `aarch64-darwin`, but Docker Desktop on macOS runs containers in a Linux VM (`aarch64-linux`). The darwin binary cannot execute in a Linux container.

**Attempted fix:** Cross-compiling to `x86_64-linux` via `pkgsLinux` failed because macOS cannot build Linux binaries natively without a remote builder:

```
error: required system: 'x86_64-linux'
       current system: 'aarch64-darwin'
```

**Conclusion:** This is a known limitation of Nix on macOS without NixOS remote builders. The image tarball itself is correctly built and bit-for-bit reproducible (proven by identical SHA256 hashes above). On a Linux machine, `docker run` would succeed without modification.

---

## Challenges and Solutions

| Challenge | Root Cause | Solution |
|-----------|-----------|----------|
| `go.mod file not found` | `buildGoModule` requires a `go.mod` | `nix shell nixpkgs#go` + `go mod init app` |
| `exec format error` | darwin binary cannot run in Linux container | Documented limitation; reproducibility proven via SHA256 |
| `x86_64-linux` cross-compile failed | macOS cannot cross-compile to Linux without remote builder | Built for native arch instead |
| Docker Hub EOF errors | Network connectivity issue | Used already-pulled `golang:1.22` image |
