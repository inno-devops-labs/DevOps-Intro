# Lab 10 Submission
## Task 1: Build Reproducible Artifacts from Scratch
### Nix Installation

**Installation Method:** Determinate Systems installer

**Verification Output:**
```
arinapetuhova@MacBook-Air-Arina ~ % nix --version
nix (Determinate Nix 3.17.1) 2.33.3
arinapetuhova@MacBook-Air-Arina ~ % nix run nixpkgs#hello
Hello, world!
```

### File: default.nix

```
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
  
  meta = {
    description = "Reproducible Go app built with Nix";
    platforms = pkgs.lib.platforms.all;
  };
}
```

**Explanation:**
- `pkgs.buildGoModule`: Nix function that builds Go applications with dependency management. It handles downloading dependencies, vendoring, and compiling Go modules in a reproducible way.
- `pname` and `version`: Package name and version. These combine to form the package identifier (app-1.0.0) in the Nix store path.
- `src = ./.`: Points to the current directory containing the source code (main.go and go.mod). Nix copies this into a sandboxed build environment.
- `vendorHash = null`: Explicitly tells Nix that this Go module has no external dependencies. When set to null, Nix skips the vendoring phase entirely. If there were dependencies, this would contain a SHA256 hash to verify the vendored dependencies match exactly.
- `meta`: Optional metadata describing the package. platforms = pkgs.lib.platforms.all indicates this package can be built on any platform supported by Nix (Linux, macOS, etc.).
- This derivation tells Nix exactly how to build the application in isolation - with no access to network, system libraries, or files outside the declared inputs, ensuring truly reproducible builds.


### Build Processes
**Build 1:**

```
arinapetuhova@MacBook-Air-Arina app % nix-build
this derivation will be built:
  /nix/store/swcxf0001b1jgas27s3zi3j6rndy5rqw-app-1.0.0.drv
building '/nix/store/swcxf0001b1jgas27s3zi3j6rndy5rqw-app-1.0.0.drv'...
Running phase: unpackPhase
unpacking source archive /nix/store/vzvszgdfjahhhwrbbbm26fifp6lcwqj2-app
source root is app
Running phase: patchPhase
Running phase: updateAutotoolsGnuConfigScriptsPhase
Running phase: configurePhase
Running phase: buildPhase
Building subPackage .
Running phase: checkPhase
Running phase: installPhase
Running phase: fixupPhase
checking for references to /nix/var/nix/builds/nix-13493-859994452/ in /nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0...
patching script interpreter paths in /nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0
stripping (with command strip and flags -S) in  /nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0/bin
/nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0
arinapetuhova@MacBook-Air-Arina app % ./result/bin/app
Built with Nix at compile time
Running at: 2026-03-30T20:05:47+03:00
arinapetuhova@MacBook-Air-Arina app % readlink result
/nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0
```

**Build 2:**

```
arinapetuhova@MacBook-Air-Arina app % rm result
nix-build
readlink result
/nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0
/nix/store/0j4vjpmafrp1nqgm02sdf71k9hlvqjz1-app-1.0.0
```

### SHA256 hash of the binary
```
arinapetuhova@MacBook-Air-Arina app % sha256sum ./result/bin/app
dfccaac1f2b92a0b7fdad2bf15bf8224792b402732c9b5f2fe1ecd1744d9900f  ./result/bin/app
```

### Comparison with Docker
Docker is not reproducible because it includes timestamps in image layers, so even with identical code, each build produces a different hash. Dockerfiles also use mutable tags like `golang:1.22` that can point to different base images over time as updates are released. Additionally, Docker builds have network access, allowing commands to fetch different dependency versions depending on when the build runs. These factors mean two developers building the same Dockerfile on different days will get different images.

### Analysis
Nix builds are reproducible because they run in complete isolation—no network access, no system files, only explicitly declared dependencies. Every build input (source code, compiler, libraries) is pinned by a cryptographic hash in the Nix store. The same inputs always produce the same outputs because Nix removes non-deterministic elements like timestamps and ensures the build environment is identical every time. This eliminates the "works on my machine" problem entirely.

### Explanation of the Nix store path format and what each part means
The Nix store path follows this format: `/nix/store/<hash>-<name>-<version>`. The hash (e.g., `0j4vjpmafrp1nqgm02sdf71k9hlvqjz1`) is a SHA256 hash of all build inputs—source code, dependencies, build scripts, compiler version, and build flags. If any input changes, the hash changes, creating a completely new store path. The `<name>-<version>` part (e.g., app-1.0.0) is just human-readable metadata. This content-addressed system ensures that identical inputs always produce identical store paths, enabling perfect reproducibility and safe sharing of build artifacts.

## Task 2: Reproducible Docker Images with Nix
### File: docker.nix:
```
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./app { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "reproducible-app";
  tag = "latest";
  contents = [ app ];
  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
```

**Explanation:**
- `pkgs.dockerTools.buildLayeredImage`: Nix function that creates efficient, layered Docker images. It builds images in a deterministic way without timestamps or non-reproducible metadata.
- `contents`: Specifies which packages or derivations to include in the image. Here, it includes our Go application (`app`) built from the previous task.
- `config.Cmd`: Defines the default command to run when the container starts. This points to the binary location in the Nix store.
- The derivation ensures that the Docker image is built in isolation with pinned dependencies, making it fully reproducible.

### Image size comparison
**Reproducible:**
```
arinapetuhova@MacBook-Air-Arina lab11 % docker images | grep reproducible-app
reproducible-app   latest    776674e7ac3a   11 seconds ago   3.24MB
```

**Traditional:**
```
arinapetuhova@MacBook-Air-Arina lab11 % docker images | grep traditional-app
traditional-app    latest    d6690fafc5cc   About a minute ago   522MB
```

The Nix-style image is 99.4% smaller than the traditional image. This size reduction comes from:

- Using FROM scratch (0 MB base image) instead of Alpine Linux
- Including only the statically compiled binary (2.06 MB) without build tools
- No runtime dependencies or package managers in the final image

### SHA256 hashes
```
arinapetuhova@MacBook-Air-Arina lab11 % echo "Test1 SHA256:"
docker inspect test1 --format='{{index .RepoDigests 0}}'

echo "Test2 SHA256:"
docker inspect test2 --format='{{index .RepoDigests 0}}'
Test1 SHA256:
test1@sha256:b2a11e12f5f31b21e17effe15aa55016ad2e63d466d9186b5cfde89ea67e1e5e
Test2 SHA256:
test2@sha256:b2a11e12f5f31b21e17effe15aa55016ad2e63d466d9186b5cfde89ea67e1e5e

```

This proves that the Docker image is truly reproducible - the same inputs always produce the exact same output, regardless of when or where the build runs.

### Docker history output for both images
**Reproducible:**
```
arinapetuhova@MacBook-Air-Arina lab11 % docker history reproducible-app:latest
IMAGE          CREATED          CREATED BY                      SIZE      COMMENT
776674e7ac3a   16 seconds ago   ENTRYPOINT ["/app"]             0B        buildkit.dockerfile.v0
<missing>      16 seconds ago   COPY /app/app /app # buildkit   2.06MB    buildkit.dockerfile.v0
```

**Traditional:**
```
arinapetuhova@MacBook-Air-Arina lab11 % docker history traditional-app:latest
IMAGE          CREATED              CREATED BY                                      SIZE      COMMENT
d6690fafc5cc   About a minute ago   ENTRYPOINT ["/app"]                             0B        buildkit.dockerfile.v0
<missing>      About a minute ago   RUN /bin/sh -c go build -o /app /app/main.go…   36MB      buildkit.dockerfile.v0
<missing>      About a minute ago   COPY app/main.go /app/main.go # buildkit        12.3kB    buildkit.dockerfile.v0
<missing>      About a minute ago   RUN /bin/sh -c apk add --no-cache go # build…   351MB     buildkit.dockerfile.v0
<missing>      2 months ago         CMD ["/bin/sh"]                                 0B        buildkit.dockerfile.v0
<missing>      2 months ago         ADD alpine-minirootfs-3.23.3-aarch64.tar.gz …   9.36MB    buildkit.dockerfile.v0
```

### Analysis
Nix-built Docker images are significantly smaller because they use FROM scratch as the base (0 MB) instead of full operating systems like Alpine Linux (9 MB), and include only the statically compiled Go binary (2 MB) without any build tools, package managers, or runtime dependencies. The traditional Docker image, by contrast, includes the entire Alpine OS, the Go compiler, source code, and build artifacts, resulting in a 522 MB image. Nix-style images are more reproducible because they use pinned versions (golang:1.22-alpine), eliminate timestamps in layers, and ensure no network access during the final build stage. Every build with the same inputs produces the identical SHA256 hash, proving that the build process is deterministic and immune to external factors like time, machine state, or network conditions.

### Layer structure comparison
- Nix-style: Only 2 layers containing just the binary and metadata
- Traditional: 5+ layers including base OS, build tools, source code, and compiled binary
- Nix-style builds produce content-addressable layers that can be reused across images
- Traditional builds create new layers for each command, even if content is identical

### Practical advantages of content-addressable Docker images
Content-addressable Docker images enable perfect cache efficiency, as identical binary layers are shared across any number of images, dramatically reducing storage and build times. They also provide cryptographic verification—the SHA256 hash serves as an immutable fingerprint, allowing teams to verify that production images exactly match security-approved builds. This eliminates the "works on my machine" problem entirely, as any developer building the same image anywhere in the world gets bit-for-bit identical results. For CI/CD pipelines, this means flaky builds disappear, and rollbacks become instant since old image versions remain in the cache with their guaranteed integrity intact.
