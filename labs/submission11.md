# Task 1 — Build Reproducible Artifacts from Scratch

## Nix installation

*nix --version*
```
nix (Determinate Nix 3.17.3) 2.33.3
```

## default.nix file with explanations

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0";

  src = ./.;

  vendorHash = null;
}
```

*Explanations:*

```
This Nix code specifies how to build the Go application using a derivation. It pulls in nixpkgs to utilize standard build utilities. The buildGoModule function is employed to manage Go-specific compilation and dependencies within an isolated sandbox. The pname and version define basic package info, while src = ./. indicates that the local directory should be used as the source. Since there are no external dependencies to verify at this stage, vendorHash is set to null.
```

## Store path from multiple builds

*First build:*

*readlink result*

```
/nix/store/pnnaxvr83hpdr1kjy5v6mmlwfalyysn3-app-1.0
```

*Second build:*

*readlink result*

```
/nix/store/pnnaxvr83hpdr1kjy5v6mmlwfalyysn3-app-1.0
```

## SHA256 hash of the binary

*SHA256*

```
da91c116d4bc422fdac7a9367e5a70981553fda40b5eaa6c7ede5711ee2c52bc  ./result/bin/app
```

## Comparison with Docker: Why is Docker not reproducible?

```
Traditional Docker builds fail to be reproducible because they rely on the environment state at the time of execution. Using commands like RUN apt-get install fetches current package versions, leading to different results over time. Furthermore, Docker images capture host-specific metadata, such as timestamps and filesystem details, and the build process depends on the local cache, preventing the creation of bit-for-bit identical hashes across different runs or environments.
```

## Analysis: What makes Nix builds reproducible?

```
Nix ensures reproducibility through sandboxed environments and content-addressing. Builds take place in isolation without network access, preventing any influence from the host system. Dependencies are linked via specific cryptographic hashes rather than generic version tags. To guarantee consistency, Nix eliminates non-deterministic data like timestamps from the build output, ensuring that identical inputs always result in the exact same store path and binary.
```

## Explanation of the Nix store path format and what each part means

```
The path /nix/store/pnnaxvr83hpdr1kjy5v6mmlwfalyysn3-app-1.0 consists of three segments. First, /nix/store/ is the global root for all Nix packages. The second part, pnnaxvr83hpdr1kjy5v6mmlwfalyysn3, is a cryptographic hash derived from the source files, build instructions, and all dependencies. The final part, app-1.0, is a human-readable identifier based on the package name and version for easier management.
```

# Task 2 — Reproducible Docker Images with Nix

## docker.nix file with explanations

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
  };
}
```

*Explanations:*

```
This file defines a reproducible Docker image using Nix. It imports the application derivation from Task 1 via a let binding. Using buildLayeredImage, it creates an image named nix-app with the tag latest. The contents field includes our compiled Go application. The config block sets the entry point to the application's binary path. Because Nix handles image construction deterministically by removing timestamps and using content-addressed layers, the resulting image is identical regardless of where or when it is built.
```

## Image size comparison: Nix vs traditional Dockerfile

```
nix-app:latest    11.9MB

test-app:latest   1.25GB
```

## SHA256 hashes proving reproducibility

*First build:*

```
sha256sum result

af814946895662386b32bf251f44da69ea09853e2fb4feb82545a985b4c1d5d4  result
```

*Second build:*

```
sha256sum result

af814946895662386b32bf251f44da69ea09853e2fb4feb82545a985b4c1d5d4  result
```

*Result: The hashes are identical.*

## Docker history output for both images

*docker history nix-app:latest*

```
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
bb9c9682f422   N/A                    8.19kB    store paths: ['/nix/store/3fcq3spba1a4g4y55jij979qzbdcwis5-nix-app-customisation-layer']
<missing>      N/A                    1.81MB    store paths: ['/nix/store/hp7j9y1qlm1d94lnpdd7w9i6y69jghda-app-1.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
```

*docker history test-app:latest*

```
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
7f7af4ddd33d   29 minutes ago   RUN /bin/sh -c go build -o app main.go # bui…   31.4MB    buildkit.dockerfile.v0
<missing>      29 minutes ago   COPY main.go . # buildkit                       12.3kB    buildkit.dockerfile.v0
<missing>      29 minutes ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      14 months ago    WORKDIR /go                                     4.1kB     buildkit.dockerfile.v0
<missing>      14 months ago    RUN /bin/sh -c mkdir -p "$GOPATH/src" "$GOPA…   16.4kB    buildkit.dockerfile.v0
<missing>      14 months ago    COPY /target/ / # buildkit                      265MB     buildkit.dockerfile.v0
<missing>      14 months ago    ENV PATH=/go/bin:/usr/local/go/bin:/usr/loca…   0B        buildkit.dockerfile.v0
<missing>      14 months ago    ENV GOPATH=/go                                  0B        buildkit.dockerfile.v0
<missing>      14 months ago    ENV GOTOOLCHAIN=local                           0B        buildkit.dockerfile.v0
<missing>      14 months ago    ENV GOLANG_VERSION=1.22.12                      0B        buildkit.dockerfile.v0
<missing>      14 months ago    RUN /bin/sh -c set -eux;  apt-get update;  a…   267MB     buildkit.dockerfile.v0
<missing>      2 years ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   194MB     buildkit.dockerfile.v0
<missing>      2 years ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   52.3MB    buildkit.dockerfile.v0
<missing>      2 years ago      # debian.sh --arch 'amd64' out/ 'bookworm' '…   133MB     debuerreotype 0.15
```

## Analysis: Why are Nix-built images smaller and more reproducible?

```
Nix images are significantly smaller because they exclude standard OS components, build tools, and package managers, including only the specific runtime dependencies needed. Standard Dockerfiles usually begin with large base images that carry unnecessary bloat. Nix ensures reproducibility by building images from deterministic store paths, stripping all timestamps, and normalizing metadata, which results in a consistent SHA256 hash across any environment.
```

## Layer structure comparison

```
The Nix image contains three distinct, optimized layers representing specific store paths: the app binary, timezone data, and a configuration layer. It lacks timestamps or auxiliary build files, keeping the total size around 7-11 MB. 

Conversely, the standard Docker image has a complex history with eleven layers, many including timestamps from years ago. It carries the weight of a full Debian system, compilers, and various environment settings. Much of its 1.25GB size is occupied by tools that aren't needed at runtime. This contrast highlights Nix's ability to produce lean, deterministic images without historical overhead.
```

## Practical advantages of content-addressable Docker images

```
Reliability - Exact image hashes ensure consistency across development and production environments.

Optimization - Duplicate layers are only stored once, speeding up downloads and saving disk space.

Integrity - Hashes provide a security guarantee that the image has not been altered.

CI Efficiency - Builds can be skipped if the input hashes remain unchanged.

Predictable Versioning - References to immutable hashes are more stable than mutable tags.

Transparency - Every layer is directly traceable to the specific inputs used for its creation.
```