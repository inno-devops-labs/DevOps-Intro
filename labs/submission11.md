# Lab 11 Submission

## Task 1 - Build Reproducible Artifacts from Scratch

### Installation steps and verification output

Nix was used in a Linux/WSL environment.

Verification command:

```bash
nix --version
```

### `default.nix` with explanation

This derivation builds the Go application with `pkgs.buildGoModule`. `cleanSourceWith` excludes `result` symlinks so local build artifacts do not affect reproducibility.

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

### Build commands

```bash
nix-build --out-link result-app
readlink result-app
sha256sum result-app/bin/app
rm result-app
nix-build --out-link result-app
readlink result-app
sha256sum result-app/bin/app
```

### Store path from multiple builds

First build:

```text
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
```

Second build:

```text
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
```

The store path is identical across both builds.

### SHA256 hash of the binary

First build:

```text
52f6fd8d8c6fab7545301b3836aee2205a366752021325972b5428d51c8227c5
```

Second build:

```text
52f6fd8d8c6fab7545301b3836aee2205a366752021325972b5428d51c8227c5
```

The SHA256 hash of the binary is identical across both builds.

### Comparison with Docker

Dockerfile used for comparison:

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

Commands:

```bash
docker build -t test-app:first .
docker build -t test-app:second .
```

Observed image IDs:

```text
sha256:74fed3621e7ebd871c12c84ebecd101247178b62f4ce5a0ba7247b571b1b67cc
sha256:675acc345c0d54a2430cdcecbeb73f1a818085ff14f30dbecb992381abae345d
```

Why Docker is not reproducible here:

- image IDs are different even with the same source code;
- Docker builds include metadata and layer differences;
- traditional Docker builds are sensitive to timestamps and builder state.

### Analysis: what makes Nix builds reproducible

Nix builds are reproducible because:

- dependencies are declared explicitly;
- builds run in an isolated environment;
- outputs are content-addressed;
- the same inputs produce the same output path and the same binary hash.

### Explanation of the Nix store path format

Example:

```text
/nix/store/l89ijlwcq74gsics8vsq9l7dfrm7mzvk-app-1.0.0
```

Meaning:

- `/nix/store` is the global Nix store;
- `l89ijlwcq74gsics8vsq9l7dfrm7mzvk` is the hash derived from build inputs;
- `app-1.0.0` is the package name and version.

## Task 2 - Reproducible Docker Images with Nix

### `docker.nix` with explanation

This expression uses `pkgs.dockerTools.buildLayeredImage` to build a Docker image from the reproducible Nix package produced in Task 1.

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

### Build commands

```bash
nix-build docker.nix --out-link result-docker
readlink result-docker
sha256sum result-docker
rm result-docker
nix-build docker.nix --out-link result-docker
readlink result-docker
sha256sum result-docker
```

### SHA256 hashes proving reproducibility

First build:

```text
/nix/store/q5gxs501jqa8l43zl4wy7jgxlcyk0dbg-nix-app.tar.gz
d8b9c8d17bd32d89c268b4a77588c528e1cb8fa15d8aa8519bc28d9ab092809b
```

Second build:

```text
/nix/store/q5gxs501jqa8l43zl4wy7jgxlcyk0dbg-nix-app.tar.gz
d8b9c8d17bd32d89c268b4a77588c528e1cb8fa15d8aa8519bc28d9ab092809b
```

Both the store path and tarball hash are identical.

### Load and run result

Commands:

```bash
docker load < result-docker
docker run --rm nix-app:1.0.0
```

Output:

```text
Built with Nix at compile time
Running at: 2026-04-16T19:36:04Z
```

### Image size comparison

```text
nix-app:1.0.0          11.2MB
traditional-app:first   1.93MB
traditional-app:second  1.93MB
```

Tarball size:

```text
1.1M result-docker
```

### Docker history comparison

Commands:

```bash
docker history nix-app:1.0.0
docker history traditional-app:first
```

Comparison:

- the Nix image history is based on Nix store contents;
- the traditional image history is based on standard Docker layers.

### Analysis

Why Nix-built images are more reproducible:

- image contents come from Nix derivations instead of imperative Docker build steps;
- the tarball hash is stable across repeated builds;
- content-addressed outputs make the image easier to reproduce and verify.

Practical advantages of content-addressable Docker images:

- easier verification of identical results;
- more predictable CI/CD behavior;
- stronger guarantees against hidden changes in the build environment.

## Bonus - Modern Nix with Flakes

### `flake.nix` with explanation

This flake pins `nixpkgs` to a specific revision and exposes both the application package and the Docker image as flake outputs.

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

      apps.${system} = {
        default = {
          type = "app";
          program = "${app}/bin/app";
        };
      };
    };
}
```

### `flake.lock` snippet showing locked dependencies

```text
rev = 50ab793786d9de88ee30ec4e4c24fb4236fc2674
narHash = sha256-/bVBlRpECLVzjV19t5KMdMFWSwKLtb5RyXdjz3LJT+g=
ref = nixos-24.11
```

### Build outputs from `nix build`

Commands:

```bash
nix flake lock
nix build path:$PWD#default --out-link result-flake-app
nix build path:$PWD#dockerImage --out-link result-flake-docker
```

Results:

```text
/nix/store/45rg17xhm3bl808wv6xbfmz1nilw5995-app-1.0.0
/nix/store/4v6pk5a9fyama0m67785bjwrvz1yxy57-nix-app.tar.gz
0a0e299562ffac795fbce54c295c4787b2c347abc80a21f1c9650959c6983c40
```

### Reflection

How Flakes improve upon traditional Nix expressions:

- dependencies are locked in `flake.lock`;
- builds are easier to reproduce across time;
- the project structure is more standardized;
- sharing the build configuration is simpler.
