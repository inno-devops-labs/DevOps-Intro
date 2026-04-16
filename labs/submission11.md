# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### Nix installation and verification

Nix was installed in WSL and verified with:

```
nix --version
```

### Application source

File: `labs/lab11/app/main.go`

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Built with Nix at compile time")
	fmt.Printf("Running at: %s\n", time.Now().Format(time.RFC3339))
}
```

### Nix derivation

File: `labs/lab11/app/default.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let
        base = builtins.baseNameOf path;
      in
      !(base == "result" || pkgs.lib.hasPrefix "result-" base);
  };
in
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  inherit src;

  vendorHash = null;

  subPackages = [ "." ];

  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "Simple reproducible Go app for Lab 11";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
```

### Reproducibility proof

Commands used:

```
nix-build --out-link result-app
readlink result-app
sha256sum result-app/bin/app
rm result-app
nix-build --out-link result-app
readlink result-app
sha256sum result-app/bin/app
```

First build:

```
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
52f6fd8d8c6fab7545301b3836aee2205a366752021325972b5428d51c8227c5
```

Second build:

```
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
52f6fd8d8c6fab7545301b3836aee2205a366752021325972b5428d51c8227c5
```

The store path and binary SHA256 were identical across both builds.

### Docker comparison

File: `labs/lab11/app/Dockerfile`

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

Commands used:

```
docker build -t test-app:first .
docker build -t test-app:second .
```

Image IDs:

```
sha256:74fed3621e7ebd871c12c84ebecd101247178b62f4ce5a0ba7247b571b1b67cc
sha256:675acc345c0d54a2430cdcecbeb73f1a818085ff14f30dbecb992381abae345d
```

The Docker image IDs were different, while the Nix store path and binary SHA256 were identical.

### Analysis

Nix builds are reproducible because dependencies are declared explicitly, builds run in an isolated environment, and outputs are stored in `/nix/store/<hash>-<name>` paths derived from the build inputs.

For this build:

```
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
```

- `l89ijlwcq74gsics8vsq9l7dfrm7mzvk` — hash-derived prefix
- `app-1.0.0` — package name and version

---

## Task 2 — Reproducible Docker Images with Nix

### Nix Docker image definition

File: `labs/lab11/app/docker.nix`

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.callPackage ./default.nix {};
  rootfs = pkgs.buildEnv {
    name = "app-rootfs";
    paths = [ app ];
    pathsToLink = [ "/bin" ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "1.0.0";

  contents = [ rootfs ];

  config = {
    Cmd = [ "/bin/app" ];
  };
}
```

### Build and reproducibility proof

Commands used:

```
nix-build docker.nix --out-link result-docker
readlink result-docker
sha256sum result-docker
rm result-docker
nix-build docker.nix --out-link result-docker
readlink result-docker
sha256sum result-docker
```

First build:

```
/nix/store/q5gxs501jqa8l43zl4wy7jgxlcyk0dbg-nix-app.tar.gz
d8b9c8d17bd32d89c268b4a77588c528e1cb8fa15d8aa8519bc28d9ab092809b
```

Second build:

```
/nix/store/q5gxs501jqa8l43zl4wy7jgxlcyk0dbg-nix-app.tar.gz
d8b9c8d17bd32d89c268b4a77588c528e1cb8fa15d8aa8519bc28d9ab092809b
```

The tarball path and SHA256 were identical across both builds.

### Load and run

Commands used:

```
docker load < result-docker
docker run --rm nix-app:1.0.0
```

Output:

```
Built with Nix at compile time
Running at: 2026-04-16T19:36:04Z
```

### Traditional Dockerfile comparison

File: `labs/lab11/app/Dockerfile.traditional`

```dockerfile
FROM golang:1.22 AS builder

WORKDIR /src

COPY go.mod ./
COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /app main.go

FROM scratch

COPY --from=builder /app /app

ENTRYPOINT ["/app"]
```

### Image size comparison

```
nix-app:1.0.0          11.2MB
traditional-app:first   1.93MB
traditional-app:second  1.93MB
```

Tarball size:

```
1.1M result-docker
```

### Docker history comparison

Commands used:

```
docker history nix-app:1.0.0
docker history traditional-app:first
```

Nix image history showed store-path-based layers.
Traditional image history showed normal Docker build layers.

### Analysis

The Nix-built Docker image was reproducible because it was built from immutable Nix store paths and produced the same tarball hash across repeated builds. In this experiment, the Nix image was not smaller than the traditional scratch-based image, but it was more reproducible.

---

## Bonus Task — Modern Nix with Flakes

### Flake definition

File: `labs/lab11/app/flake.nix`

```nix
{
  description = "Lab 11 reproducible Go app and Docker image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      src = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter = path: type:
          let
            base = builtins.baseNameOf path;
          in
          !(base == "result" || pkgs.lib.hasPrefix "result-" base);
      };

      app = pkgs.buildGoModule {
        pname = "app";
        version = "1.0.0";
        inherit src;
        vendorHash = null;
        subPackages = [ "." ];
        ldflags = [ "-s" "-w" ];

        meta = with pkgs.lib; {
          description = "Simple reproducible Go app for Lab 11";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      rootfs = pkgs.buildEnv {
        name = "app-rootfs";
        paths = [ app ];
        pathsToLink = [ "/bin" ];
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "nix-app";
        tag = "1.0.0";
        contents = [ rootfs ];
        config = {
          Cmd = [ "/bin/app" ];
        };
      };
    in
    {
      packages.${system} = {
        default = app;
        app = app;
        dockerImage = dockerImage;
      };

      apps.${system}.default = {
        type = "app";
        program = "${app}/bin/app";
      };
    };
}
```

### Locked dependencies

File: `labs/lab11/app/flake.lock`

Locked values:

```
rev = 50ab793786d9de88ee30ec4e4c24fb4236fc2674
narHash = sha256-/bVBlRpECLVzjV19t5KMdMFWSwKLtb5RyXdjz3LJT+g=
ref = nixos-24.11
```

### Build outputs

Commands used:

```
nix flake lock
nix build path:/mnt/c/Users/Roman/Documents/GitCourse/DevOps-Intro/labs/lab11/app#default --out-link result-flake-app
nix build path:/mnt/c/Users/Roman/Documents/GitCourse/DevOps-Intro/labs/lab11/app#dockerImage --out-link result-flake-docker
```

Results:

```
/nix/store/45rg17xhm3bl808wv6xbfmz1nilw5995-app-1.0.0
/nix/store/4v6pk5a9fyama0m67785bjwrvz1yxy57-nix-app.tar.gz
0a0e299562ffac795fbce54c295c4787b2c347abc80a21f1c9650959c6983c40
```

### Reflection

Flakes improve reproducibility by locking dependencies and making builds more repeatable across time and machines.

---

## Task completion status

- Task 1 — Build Reproducible Artifacts from Scratch
- Task 2 — Reproducible Docker Images with Nix
- Bonus Task — Modern Nix with Flakes

