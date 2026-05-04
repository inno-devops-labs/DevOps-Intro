# Lab 11 — Reproducible Builds with Nix

**Platform:** WSL2 (Ubuntu 24.04.2 LTS) on Windows 11  
**Student:** Lev Permiakov  
**Date:** 2026-05-04  

---

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1 Environment Setup

```
# Install Nix (Determinate Systems)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
exec $SHELL
nix --version
# Output: nix (Determinate Nix 3.19.0) 2.34.6
```

### 1.2 Application Files

**main.go:**
```
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

**go.mod:**
```
module app
go 1.22
```

**default.nix:**
```
{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule rec {
  pname = "app";
  version = "0.1.0";
  src = ./.;
  vendorHash = null;  # no external dependencies
  doCheck = false;
  modVendor = false;
}
```

### 1.3 Reproducibility Verification

**First build:**
```
$ nix-build
/nix/store/r7kcjs6976b4bviwyww1qzr0h6jl5q1r-app-0.1.0

$ readlink result
/nix/store/r7kcjs6976b4bviwyww1qzr0h6jl5q1r-app-0.1.0

$ sha256sum ./result/bin/app
99efa7adac0d8fa51ce4088f1c1a9edf9e70f21c2f8bbe885ca25d16dcded35f  ./result/bin/app
```

**Second build (after `rm result`):**
```
$ nix-build
/nix/store/r7kcjs6976b4bviwyww1qzr0h6jl5q1r-app-0.1.0  # identical path

$ sha256sum ./result/bin/app
99efa7adac0d8fa51ce4088f1c1a9edf9e70f21c2f8bbe885ca25d16dcded35f  # identical hash
```

### 1.4 Docker Comparison (Non-Reproducible)

**Dockerfile:**
```
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

**Build results:**
```
# First build: 25.9s, manifest sha256:fc25df0714bc7a2c902c4988f22dae3e1f34e2848f9875b64672c06a5e662bbf
# Second build: 1.0s (cached), attestation manifest sha256:d2051970a0e94700862b511a4fc7900d6edef1edd519fb0e74f81912a6469ec2
```

**Observation:** Despite layer caching, Docker generates different metadata hashes (attestation manifests, config) between builds due to timestamps and build context variations.

### 1.5 Analysis: Why Nix is Reproducible

| Factor | Nix | Traditional Docker |
|--------|-----|-------------------|
| **Dependency resolution** | Pinned via nixpkgs hash | `apt-get`/`go get` may fetch newer versions |
| **Build isolation** | Sandboxed, pure environment | Inherits host environment variables |
| **Output addressing** | Content-addressable store path | Layers with timestamps and metadata |
| **Hash determinism** | Same inputs → same path | Same Dockerfile ≠ same image hash |

**Nix Store Path Format:**  
`/nix/store/<hash>-<name>-<version>`  
- `<hash>`: SHA-256 of all build inputs (source, dependencies, build script, environment)  
- Guarantees: identical inputs → identical outputs

---

## Task 2 — Reproducible Docker Images with Nix

### 2.1 Nix Docker Definition (`docker.nix`)

```
{ pkgs ? import <nixpkgs> {} }:
let
  app = pkgs.buildGoModule {
    pname = "app";
    version = "0.1.0";
    src = ./.;
    vendorHash = null;
    doCheck = false;
    modVendor = false;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";
  contents = [ app pkgs.cacert ];
  config = {
    Entrypoint = [ "${app}/bin/app" ];
    Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  };
  created = "1970-01-01T00:00:01Z";  # fixed timestamp
}
```

### 2.2 Build and Execution

```
# Convert line endings (important for WSL/Windows)
$ dos2unix docker.nix default.nix

# Build image
$ nix-build docker.nix
/nix/store/s93ki1a13y5iba2n5fq5bi8iwlbvhwnx-nix-app.tar.gz

# Load into Docker (result is a file, not a directory!)
$ docker load < result
Loaded image: nix-app:latest

# Check size
$ docker images | grep nix-app
nix-app    latest    2b4bb772d276    56 years ago    11.9MB

# Run container
$ docker run --rm nix-app:latest
Built with Nix at compile time
Running at: 2026-05-04T08:54:39Z
```

### 2.3 Reproducibility Proof

**First image build:**
```
$ sha256sum result
b6031c47c41dafbf8678b0db1355565b93794c6f50ec6ea9789f7ea8a0b7b23a  result
```

**Second build (after `rm result`):**
```
$ nix-build docker.nix
/nix/store/bj3317qsim9d5l3b0hb43wqm841083mg-nix-app.tar.gz

$ sha256sum result
b6031c47c41dafbf8678b0db1355565b93794c6f50ec6ea9789f7ea8a0b7b23a  result  # identical hash
```

### 2.4 Comparison: Nix vs Traditional Docker

| Characteristic | Nix Image (`nix-app`) | Traditional (`test-app`) |
|---------------|----------------------|--------------------------|
| **Size** | 11.9 MB | ```850 MB |
| **Base Image** | scratch + minimal dependencies | golang:1.22 (full) |
| **Layers** | 3 deterministic | 12+ with timestamps |
| **`created` label** | `1970-01-01T00:00:01Z` (fixed) | Current build time |
| **Reproducibility** | Bit-for-bit identical hashes | Metadata hashes change |

**Conclusion:** `dockerTools` creates minimal images without timestamps or extra layers, ensuring full bit-for-bit reproducibility.

---

## Challenges and Solutions

| Problem | Solution |
|----------|---------|
| **CRLF line endings** | `dos2unix docker.nix default.nix` before building |
| **`vendorHash` error** | Set `vendorHash = null` for projects without external dependencies |
| **`result` is a file, not a directory** | Use `docker load < result`, not `result/nix-app.tar.gz` |
| **Paths with spaces in WSL** | Use quotes: `cd "/mnt/c/Users/.../lab11/app"` |

---

## Summary

Both tasks were completed successfully:

- **Task 1:** Built a Go application with Nix and verified bit-for-bit reproducibility across multiple builds. Store path and SHA-256 hash remained identical — proving that Nix eliminates environment-dependent variations.

- **Task 2:** Produced a minimal Docker image (11.9 MB) using `dockerTools`. Unlike traditional Docker builds, the Nix-built image uses fixed timestamps and deterministic layers, resulting in identical tarball hashes on every rebuild.

The key takeaway is that Nix enforces reproducibility at the build level: every input is explicitly declared, the build environment is sandboxed, and outputs are content-addressed. This eliminates the classic "works on my machine" problem — the same expression yields the same binary, on any machine, at any time.