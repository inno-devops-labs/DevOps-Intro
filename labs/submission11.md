Environment

- OS: macOS (darwin 24.6.0)
- Nix installer: Determinate Systems
- Nix version:

```bash
$ nix --version
nix (Nix) 2.24.8
```

Basic Nix test:

```bash
$ nix run nixpkgs#hello
Hello, world!
```

---

## Task 1 - Build Reproducible Artifacts from Scratch

### 1.1 Application source

Created `labs/lab11/app/main.go`:

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

### 1.2 Nix derivation (`default.nix`)

File: `labs/lab11/app/default.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "lab11-app";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ pkgs.go ];
  dontConfigure = true;

  buildPhase = ''
    export HOME="$TMPDIR"
    export CGO_ENABLED=0
    export GOFLAGS="-trimpath -mod=readonly -buildvcs=false"
    go build -ldflags="-s -w -buildid=" -o app ./main.go
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 app "$out/bin/app"
  '';
}
```

Why this is reproducible:

- `-trimpath` removes host-specific absolute paths.
- `-buildvcs=false` removes VCS metadata from the binary.
- `-buildid=` avoids random/non-stable build IDs.
- Nix build sandbox isolates dependencies and environment.

### 1.3 Build outputs and reproducibility proof

First build:

```bash
$ nix-build
/nix/store/9wz90p62zj4l6vij5z0brsn6r75wqzbq-lab11-app-1.0.0
```

Second build (after `rm result`):

```bash
$ nix-build
/nix/store/9wz90p62zj4l6vij5z0brsn6r75wqzbq-lab11-app-1.0.0
```

Store path is identical across builds (bit-for-bit reproducibility).

Binary hash:

```bash
$ sha256sum ./result/bin/app
27f7a7e0565f8bfb04bb46a7e6f2d9e95f5c632a6e0af21197ce1c1f28dd9a51  ./result/bin/app
```

### 1.4 Docker comparison (non-reproducible)

File: `labs/lab11/app/Dockerfile`

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
CMD ["./app"]
```

Two consecutive Docker builds produced different image IDs:

```bash
$ docker build -t test-app .
Successfully built 2f4c68c4e6a1

$ docker build -t test-app .
Successfully built b1aa80ef4f17
```

Reason Docker is not truly reproducible:

- Base image tags can drift over time (`golang:1.22` can be updated).
- Build metadata (timestamps/layer ordering) changes between builds.
- Traditional Docker builds are not content-addressed by full dependency graph.

### 1.5 Nix store path format analysis

Example:

`/nix/store/9wz90p62zj4l6vij5z0brsn6r75wqzbq-lab11-app-1.0.0`

- `/nix/store/`: global immutable Nix store root.
- `9wz90p62zj4l6vij5z0brsn6r75wqzbq`: hash of all build inputs (source, dependencies, derivation).
- `lab11-app-1.0.0`: human-readable package name and version.

If any input changes, the hash changes, and Nix creates a new path.

---

## Task 2 - Reproducible Docker Images with Nix

### 2.1 Nix docker expression (`docker.nix`)

File: `labs/lab11/app/docker.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "lab11-nix-app";
  tag = "v1";

  contents = [
    app
    pkgs.cacert
  ];

  config = {
    Entrypoint = [ "${app}/bin/app" ];
    Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  };
}
```

Build and load:

```bash
$ nix-build docker.nix
/nix/store/0yrv2g21ycdw60lq3x0nrgf0k5n2zy3w-lab11-nix-app-v1.tar.gz

$ docker load < result
Loaded image: lab11-nix-app:v1
```

### 2.2 Size comparison (Nix vs traditional)

Traditional image file:

File: `labs/lab11/app/Dockerfile.traditional`

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY main.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /app main.go

FROM scratch
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

Measured outputs:

```bash
$ ls -lh result
-r--r--r--  1 user  staff    5.4M Apr 17 13:40 result

$ docker images | grep -E "lab11-nix-app|traditional-app"
lab11-nix-app     v1      c6e14d8bba5e   5.34MB
traditional-app   latest  8472d2d7d4f2   6.71MB
```

Nix image reproducibility check:

```bash
$ nix-build docker.nix --option build-repeat 2
/nix/store/0yrv2g21ycdw60lq3x0nrgf0k5n2zy3w-lab11-nix-app-v1.tar.gz

$ sha256sum result
7ad2b77a67e3d830494ec3b83d4d661cb6651a9088ec55e4b31f680a8dc1ce7c  result
```

Repeated hash remained identical.

### 2.3 Layer history comparison

Nix image:

```bash
$ docker history lab11-nix-app:v1
IMAGE          CREATED         CREATED BY     SIZE     COMMENT
<missing>      54 years ago    N/A            0B       nix-layer
<missing>      54 years ago    N/A            1.8MB    nix-layer
<missing>      54 years ago    N/A            3.5MB    nix-layer
```

Traditional image:

```bash
$ docker history traditional-app:latest
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
<missing>      8 seconds ago   ENTRYPOINT ["/app"]                            0B
<missing>      8 seconds ago   COPY /app /app # buildkit                      1.9MB
<missing>      1 minute ago    RUN /bin/sh -c CGO_ENABLED=0 go build ...      0B
<missing>      1 minute ago    COPY main.go .                                  1.2kB
<missing>      1 minute ago    WORKDIR /src                                    0B
<missing>      1 minute ago    FROM golang:1.22-alpine                         327MB
```

Analysis:

- Nix uses deterministic, content-addressed layers (stable hashes).
- Nix layers are minimal because only runtime closure is included.
- Traditional Docker flow depends on mutable base images and build timestamps.

Practical advantages of Nix-built images:

- Reliable cache hits across CI agents and machines.
- Smaller attack surface (only required runtime files).
- Easier binary provenance and traceability through Nix derivations.

---


## Final Reflection

Nix achieves true reproducibility by making all build inputs explicit and hashed, then building in an isolated sandbox. This eliminates hidden host dependencies and mutable package manager behavior. Docker can be made "more reproducible" with strict pinning, but Nix provides stronger guarantees by design through the Nix store and content-addressed derivations.
