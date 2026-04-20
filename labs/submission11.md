# Lab 11 Submission

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1 Install Nix Package Manager

I installed Nix in WSL2 using the Determinate Systems installer:

```bash
curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

After installation, I loaded the Nix environment in the current shell:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

I verified the installation with:

```bash
nix --version
```

Output:

```text
nix (Determinate Nix 3.17.3) 2.33.3
```

I also confirmed that Nix could run packages:

```bash
nix run nixpkgs#hello
```

Output:

```text
Hello, world!
```

### 1.2 Create a Simple Application

I created the application in the following directory:

```text
/mnt/c/Users/vlada/DevOps-Intro/labs/lab11/app
```

The Go program source code was:

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

### 1.3 Write a Nix Derivation

I created `default.nix` with the following derivation:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "reproducible-go-app";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  subPackages = [ "." ];

  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "A simple reproducible Go app built with Nix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
```

Since `buildGoModule` requires a Go module, I initialized the module and created `go.mod`.

### 1.4 Prove Reproducibility

I built the package with Nix and obtained the output path:

```text
/nix/store/jv26r3sqjn45cky59xks1azqi1p98xcl-reproducible-go-app-1.0.0
```

The resulting binary was located at:

```text
result/bin/reproducible-go-app
```

I ran the binary successfully:

```text
Built with Nix at compile time
Running at: 2026-04-20T21:35:19+03:00
```

I computed the SHA-256 hash of the binary:

```text
4a161a9ab53f94a0876eea0d6399eb6bd921cc2dc55e3f36e358a99bb8b71041
```

I then removed the `result` symlink and rebuilt the package twice. Both builds produced the same store path:

```text
/nix/store/jv26r3sqjn45cky59xks1azqi1p98xcl-reproducible-go-app-1.0.0
```

Both builds also produced the same binary hash:

```text
4a161a9ab53f94a0876eea0d6399eb6bd921cc2dc55e3f36e358a99bb8b71041
```

Final reproducibility check result:

```text
REPRODUCIBLE
```

## Task 2 — Reproducible Docker Images with Nix

First, I built the same application using a regular Dockerfile:

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

Two cached Docker builds produced the same image ID:

```text
test-app:build1 -> fb4db597a82d
test-app:build2 -> fb4db597a82d
```

However, when I rebuilt twice with `--no-cache`, the image IDs were different:

```text
test-app:nocache1 -> 0ffce41762ce
test-app:nocache2 -> 8af71ebc2957
```

Both images had the same size:

```text
852MB
```

This showed that ordinary Docker builds were not reproducible without relying on cache.

Next, I created `docker.nix` using `dockerTools.buildImage`:

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildImage {
  name = "nix-repro-app";
  tag = "latest";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ app ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Cmd = [ "/bin/reproducible-go-app" ];
  };
}
```

I built the Nix-based Docker image tarball and obtained:

```text
/nix/store/silcc2qz3jm4nz44yyniisp8fnacjvyv-docker-image-nix-repro-app.tar.gz
```

I computed its SHA-256 hash:

```text
8d556a582c3e40141bc7780f293faed094b3851c23c05754515266f5d8ad3048
```

I rebuilt the image using the local `nixpkgs` channel path and obtained the same output path again:

```text
/nix/store/silcc2qz3jm4nz44yyniisp8fnacjvyv-docker-image-nix-repro-app.tar.gz
```

The final reproducibility check result was:

```text
REPRODUCIBLE
```

I loaded the image into Docker and ran the container successfully.

`docker load` output:

```text
Loaded image: nix-repro-app:latest
```

`docker run --rm nix-repro-app:latest` output:

```text
Built with Nix at compile time
Running at: 2026-04-20T22:29:29Z
```

## Bonus Task — Modern Nix with Flakes

I created `flake.nix` to define the package, Docker image, and development shell using the modern Nix flakes workflow.

The flake used `nixpkgs` from `github:NixOS/nixpkgs/nixos-unstable` and exposed:
- a default package for the Go application
- a default Docker image built with `dockerTools.buildImage`
- a development shell with `go` and `gopls`

I then generated `flake.lock` with:

```bash
nix flake update
```

This created a lock entry for `nixpkgs`:

```text
github:NixOS/nixpkgs/b12141e (2026-04-18)
```

Because flakes only include git-tracked files in the source, I added the application files to git tracking and then built the flake successfully with:

```bash
nix build
```

The build completed successfully, confirming that the application could also be built using the flake-based workflow.

Final directory contents:

```text
Dockerfile
default.nix
docker.nix
flake.lock
flake.nix
go.mod
index.html
main.go
result -> /nix/store/cj0rn2y5bv55nzqlks9b120alqfnqqc6-reproducible-go-app-1.0.0
```
