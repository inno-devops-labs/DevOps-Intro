# Task 1 — Build Reproducible Artifacts from Scratch (6 pts)

## Nix installlation

*nix --version*
```
nix (Determinate Nix 3.17.3) 2.33.3
```

## default.nix file with explanations

```
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
This expression defines a Nix derivation for building the Go application. It first imports the Nix Packages collection (nixpkgs) to access the standard build functions. The buildGoModule function is used specifically for Go projects, handling dependency management and compilation in a sandboxed environment. Here, pname and version set the package metadata, src = ./. tells Nix to copy all files from the current directory into the build sandbox, and vendorHash = null signals that the project currently has no external Go dependencies to fetch and verify.
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
Docker builds are inherently non-reproducible because they capture the state of the system at the exact moment the build runs. A RUN apt-get install command will download whatever the latest version of a package is in the repository at that specific time, meaning a build today and a build next month will produce different images with different binaries. Additionally, Dockerfiles introduce timestamps and filesystem metadata into layer creation, and the build cache varies based on the host machine's state, making it impossible to guarantee the same exact byte-for-byte image hash across different machines or different times.
```


## Analysis: What makes Nix builds reproducible?

```
Nix achieves reproducibility through a combination of sandboxed builds and content-addressable storage. Every build runs in complete isolation with no network access and no access to files outside the declared inputs, eliminating hidden dependencies on the host system. All dependencies are precisely pinned by their cryptographic hash, not by mutable names like "latest" or "1.22," so the exact same inputs are guaranteed every time. Finally, Nix normalizes build outputs by stripping timestamps and non-deterministic metadata, ensuring that identical inputs produce bit-for-bit identical outputs in the Nix store, represented by the same unique store path hash regardless of when or where the build occurs.
```

## Explanation of the Nix store path format and what each part means

```
The path /nix/store/pnnaxvr83hpdr1kjy5v6mmlwfalyysn3-app-1.0 breaks down into three meaningful pieces. The first part, /nix/store/, is the permanent directory where Nix keeps everything it builds, completely separate from the rest of your system files. The middle string, pnnaxvr83hpdr1kjy5v6mmlwfalyysn3, is a unique fingerprint generated from the exact contents of your source code, your build instructions, and every dependency involved in creating the application. Finally, the suffix app-1.0 is just a friendly label taken from the package name and version you set in your derivation so you can easily recognize what is inside without decoding the hash.
```

# Task 2 — Reproducible Docker Images with Nix (4 pts)

## docker.nix file with explanations

```
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
This Nix expression builds a reproducible Docker image containing the application we created in Task 1. The file begins by importing nixpkgs to access Nix's collection of build utilities, including the dockerTools functions. A let binding is used to import the default.nix derivation from Task 1 and assign it to the variable app, making it available for inclusion in the image. The buildLayeredImage function then constructs a Docker image with the name nix-app and the tag latest. The contents list specifies what should be placed inside the image, and here we include our entire app derivation, which contains the compiled Go binary at /bin/app. Finally, the config section sets the default command that runs when the container starts, pointing to our binary's location. Because Nix builds this image from content-addressable components and strips away timestamps and non-deterministic metadata, building this same expression on any machine or at any time will produce a byte-for-byte identical Docker image tarball.
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
Nix-built images are smaller because they include only the exact runtime dependencies the application needs, with no operating system, no package manager, and no build toolchains. Traditional Docker images start from base images like ubuntu that pull in hundreds of unnecessary files. For reproducibility, Nix images are built from content-addressable store paths where every layer has a deterministic hash, all timestamps are stripped, and metadata is normalized to fixed values. This guarantees that rebuilding the same Nix expression produces a byte-for-byte identical image tarball with the same SHA256 hash every time, on any machine.
```

## Layer structure comparison

```
The Nix-built image shows exactly three clean layers, each corresponding to a specific Nix store path. The layers are named by their content hash and contain only what is strictly necessary: the application binary, timezone data, and a minimal customization layer. There are no timestamps, no shell history, and no intermediate build artifacts. The total size is just over 7 MB.

The traditional Docker image, in contrast, reveals a much messier history with eleven layers spanning over two years of timestamps. It includes the entire Debian base system, apt package manager operations, the Go toolchain, environment variable declarations, and the compiled binary itself. Many of these layers contain build-time dependencies and system utilities that are completely unnecessary at runtime. The image size exceeds 265 MB, most of which is wasted space for a simple Go binary that could otherwise be a few megabytes. This comparison visually demonstrates why Nix images are both smaller and truly reproducible while traditional Docker builds accumulate historical cruft and non-deterministic timestamps.
```


## Practical advantages of content-addressable Docker images

```
Bit-for-bit reproducibility - The same image hash always means the exact same contents, eliminating "works on my machine" problems

Efficient storage and transfer - Identical layers are stored once and shared across images, reducing disk usage and pull times

Strong security guarantees - The hash verifies integrity, ensuring the image has not been tampered with

Simplified caching - CI/CD pipelines can skip rebuilding when inputs haven't changed

Easy rollbacks - Precise image versions can be referenced by their immutable hash rather than mutable tags

Auditability - Every layer maps directly to a known set of source inputs and dependencies
```




