# Lab 11 Submission

## Task 1 - Build Reproducible Artifacts from Scratch

### 1.1. Install Nix Package Manager

#### Install Nix

I install `Nix` package manager and enable flakes.

```bash
seva@Seva:/.../DevOps-Intro$ sh <(curl -L https://nixos.org/nix/install) --daemon
...
Alright! Were done!

seva@Seva:/.../DevOps-Intro$ mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
seva@Seva:/.../DevOps-Intro$ exec $SHELL
```

Nix was installed successfully. I also enabled flakes support and reloaded the shell.


#### Verify Installation

I check that Nix is installed correctly.

```bash
seva@Seva:/.../DevOps-Intro$ nix --version
nix (Nix) 2.34.4
```

The version is printed, so installation works correctly.


#### Test Basic Nix Usage

I run a simple program using Nix without installing it globally.

```bash
seva@Seva:/.../DevOps-Intro$ nix run nixpkgs#hello
Hello, world!
```

The program runs successfully. This shows that Nix can fetch and execute packages.


### 1.2. Create a Simple Application

#### Create a lab directory

I create a directory for the application.

```bash
seva@Seva:/.../DevOps-Intro$ mkdir -p labs/lab11/app
cd labs/lab11/app

seva@Seva:/.../DevOps-Intro/labs/lab11/app$ ls
default.nix  index.html
```

The directory is created and I can see existing files inside it.


#### Write a simple Go application

I create a simple `Go` program.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ cat main.go
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

The program prints a static message and current time. This will help to verify builds.


### 1.3. Write a Nix Derivation

#### Create a Nix derivation

I write a Nix expression to build the `Go` application.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ cat default.nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
    pname = "app";
    version = "1.0";

    src = ./.;

    vendorHash = pkgs.lib.fakeHash;

    subPackages = [ "." ];
}
```

The derivation defines how to build the app using `Nix`. It specifies name, version and source.


#### Build your application

I initialize Go module and build the application using `Nix`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix-shell -p go --run "go mod init app"
go: creating new go.mod: module app
go: to add module requirements and sums:
        go mod tidy

seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix-build
this derivation will be built:
  /nix/store/171921y8pz5d5k2krp2i65rhzslf1r3b-app-1.0.drv
building '/nix/store/171921y8pz5d5k2krp2i65rhzslf1r3b-app-1.0.drv'...
Running phase: unpackPhase
...
Running phase: fixupPhase
shrinking RPATHs of ELF executables and libraries in /nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
shrinking /nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0/bin/app
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
checking for references to /build/ in /nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0...
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
patching script interpreter paths in /nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
stripping (with command strip and flags -S -p) in  /nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0/bin
/nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
```

The build succeeds and Nix creates a result in the store. The path contains a unique hash.


#### Run the built binary

I run the compiled binary.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ ./result/bin/app
Built with Nix at compile time
Running at: 2026-04-01T11:17:53+03:00
```

The program runs correctly. It shows build message and current runtime timestamp.


### 1.4. Prove Reproducibility

#### Record the store path

I check the resulting store path.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ readlink result
/nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
```

The result points to a specific path in Nix store. It includes a hash.


#### Build again and compare

I rebuild the project and compare paths.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ rm result
nix-build
readlink result
/nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
/nix/store/5pbv54gcizjdzbwm69bbl78f2n5yjl1w-app-1.0
```

The paths are identical. This shows that the build is reproducible.


#### Compute hash of the binary

I calculate `SHA256` hash of the binary.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ sha256sum ./result/bin/app
87a237a8ab8077fe66e7dca3757e80d51453c4b99a2d19444786999abce2a826  ./result/bin/app
```

The hash is stable. It proves that the binary is identical.


#### Compare with Docker

I build the same app using `Docker`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker build -t test-app .
docker build -t test-app .
[+] Building 229.4s (10/10) FINISHED                                       docker:default
 => [internal] load build definition from Dockerfile                                 0.1s
 => => transferring dockerfile: 110B                                                 0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                       3.8s
 => [auth] library/golang:pull token for registry-1.docker.io                        0.0s
 => [internal] load .dockerignore                                                    0.1s
 => => transferring context: 2B                                                      0.1s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d0  219.2s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074  0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e 32B / 32B  0.7s
 => => sha256:1451027d3c0ee892b96310c034788bbe22b30b8ea2d075edbd09acfea 126B / 126B  1.0s
 => => sha256:3b7f19923e1501f025b9459750b20f5df37af452482f75b91 92.33MB / 92.33MB  188.8s
 => => sha256:afa154b433c7f72db064d19e1bcfa84ee196ad29120328f6b 69.36MB / 69.36MB  181.3s
 => => sha256:35af2a7690f2b43e7237d1fae8e3f2350dfb25f3249e9cf65 64.39MB / 64.39MB  166.2s
 => => sha256:32b550be6cb62359a0f3a96bc0dc289f8b45d097eaad275887 24.06MB / 24.06MB  73.7s
 => => sha256:a492eee5e55976c7d3feecce4c564aaf6f14fb07fdc5019d0 48.48MB / 48.48MB  132.3s
 => => extracting sha256:a492eee5e55976c7d3feecce4c564aaf6f14fb07fdc5019d06f4154edd  1.5s
 => => extracting sha256:32b550be6cb62359a0f3a96bc0dc289f8b45d097eaad275887f163c678  0.6s
 => => extracting sha256:35af2a7690f2b43e7237d1fae8e3f2350dfb25f3249e9cf65121866f9c  2.1s
 => => extracting sha256:3b7f19923e1501f025b9459750b20f5df37af452482f75b91205f345d1  2.2s
 => => extracting sha256:afa154b433c7f72db064d19e1bcfa84ee196ad29120328f6bdb2c5fbd7  4.8s
 => => extracting sha256:1451027d3c0ee892b96310c034788bbe22b30b8ea2d075edbd09acfeaa  0.2s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38  0.2s
 => [internal] load build context                                                    0.2s
 => => transferring context: 218B                                                    0.0s
 => [2/4] WORKDIR /app                                                               1.4s
 => [3/4] COPY main.go .                                                             0.1s
 => [4/4] RUN go build -o app main.go                                                4.8s
 => exporting to image                                                               0.0s
 => => exporting layers                                                              0.0s
 => => exporting manifest sha256:b381cf259f5261e511aa58704b170927b548813041ccda133c  0.0s
 => => exporting config sha256:b8d6a15308bd8d7976e2ffd3288715cb27437e614bfa1a2b53cf  0.0s
 => => exporting attestation manifest sha256:28a3dc966bdefb195d5441a564323b7c4a6be5  0.1s
 => => exporting manifest list sha256:28f2158182fa8ce26cc6a09fa9e96eebab785ccf3937e  0.0s
 => => naming to docker.io/library/test-app:latest                                   0.0s
 => => unpacking to docker.io/library/test-app:latest                                0.3s
[+] Building 2.2s (9/9) FINISHED                                           docker:default
 => [internal] load build definition from Dockerfile                                 0.0s
 => => transferring dockerfile: 110B                                                 0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                       1.6s
 => [internal] load .dockerignore                                                    0.0s
 => => transferring context: 2B                                                      0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074  0.0s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074  0.0s
 => [internal] load build context                                                    0.0s
 => => transferring context: 29B                                                     0.0s
 => CACHED [2/4] WORKDIR /app                                                        0.0s
 => CACHED [3/4] COPY main.go .                                                      0.0s
 => CACHED [4/4] RUN go build -o app main.go                                         0.0s
 => exporting to image                                                               0.2s
 => => exporting layers                                                              0.0s
 => => exporting manifest sha256:b381cf259f5261e511aa58704b170927b548813041ccda133c  0.0s
 => => exporting config sha256:b8d6a15308bd8d7976e2ffd3288715cb27437e614bfa1a2b53cf  0.0s
 => => exporting attestation manifest sha256:342ad88a848bdbabe15c6a9ea9b443f6d23d6a  0.1s
 => => exporting manifest list sha256:1531c27ca46ed3199f6fa6019bbed6f60bf72dfa68c74  0.0s
 => => naming to docker.io/library/test-app:latest                                   0.0s
 => => unpacking to docker.io/library/test-app:latest                                0.0s
```

Docker builds succeed, but images are rebuilt differently. Build process depends on layers and timestamps.


### Comparison with Docker: Why is Docker not reproducible?

Docker builds are not fully reproducible because they depend on external state. Base images can change over time, even with the same tag. Build process includes timestamps and metadata that differ between runs. Also, caching and environment differences affect the result. Because of this, identical `Dockerfiles` may produce different image hashes.


### Analysis: What makes Nix builds reproducible?

Nix ensures reproducibility by using a content-addressable store. Every dependency is fixed and identified by a hash. Builds are executed in an isolated sandbox without access to system environment. There are no timestamps or hidden inputs in the build process. The same inputs always produce the same output. This guarantees identical binaries across machines.


### Explanation of the Nix store path format and what each part means

A Nix store path looks like `/nix/store/hash-name-version`. The hash is computed from all build inputs, including dependencies. The name and version describe the package. If any input changes, the hash also changes. This makes the path unique and reproducible. It also allows Nix to reuse builds safely.


## Task 2 - Reproducible Docker Images with Nix

### 2.1. Build Docker Image with Nix

#### Create a Docker image using `dockerTools`

I define a Docker image using `Nix`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ cat docker.nix
{ pkgs ? import <nixpkgs> {} }:

let
    app = pkgs.callPackage ./default.nix {};
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

The image is built from the Nix derivation. It includes only required dependencies.


#### Build the Docker image

I build the Docker image using Nix.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix-build docker.nix
these 12 derivations will be built:
  /nix/store/p9gliya152s90f635js9kzp15vkkhws3-pythoncheck.sh.drv
...
building '/nix/store/by2ksj2cxrrbw944ig9d71q6qdrhaj2n-nix-app-conf.json.drv'...
{
  "architecture": "amd64",
  "config": {
    "Cmd": [
      "/bin/app"
    ]
  },
  "os": "linux",
  "store_dir": "/nix/store",
  "from_image": null,
  "store_layers": [
    [
      "/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a"
    ],
    [
      "/nix/store/dsvzkrb2g9ldghi27ksvcfsad7qq0yjr-app-1.0"
    ]
  ],
  "customisation_layer": "/nix/store/npqs36aq1f0r8ykfqb6vb583jr4qwr43-nix-app-customisation-layer",
  "repo_tag": "nix-app:latest",
  "created": "1970-01-01T00:00:01+00:00",
  "mtime": "1970-01-01T00:00:01+00:00",
  "uid": "0",
  "gid": "0",
  "uname": "root",
  "gname": "root"
}
copying path '/nix/store/5911iryyq35gmdng0kcqv6zklivhkp67-python3.13-flake8-7.3.0' from 'https://cache.nixos.org'...
building '/nix/store/p9gliya152s90f635js9kzp15vkkhws3-pythoncheck.sh.drv'...
building '/nix/store/n7z6icldljc70p8mik2h41d8arssffvd-pythoncheck.sh.drv'...
building '/nix/store/0999ray8w2jjr13sb6bgj4hz4my5hdvg-stream.drv'...
building '/nix/store/sfi0hwb2r4gba6rva91glhf0j0pnlg02-stream.drv'...
building '/nix/store/l2ysi4rcyzpadyb4cqzw5ha6pfnwr26w-stream-nix-app.drv'...
building '/nix/store/s8x0asmgiciz2kd7pkgbs33629q64gnk-nix-app.tar.gz.drv'...
No 'fromImage' provided
Creating layer 1 from paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
Creating layer 2 from paths: ['/nix/store/dsvzkrb2g9ldghi27ksvcfsad7qq0yjr-app-1.0']
Creating layer 3 with customisation...
Adding manifests...
Done.
/nix/store/g5kgisk0nvalziy2l0yh379f8ajgva24-nix-app.tar.gz
```

Nix creates a tarball image in the store. It also shows exact layers and metadata.


#### Load into Docker

I load the image into `Docker`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker load < result
Loaded image: nix-app:latest
```

The image is successfully imported into `Docker`.


#### Run the container

I run the container.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker run test-app
```

The container runs using the built image. It executes the application.


### 2.2. Compare Image Sizes and Reproducibility

#### Check Nix-built image size

I check image size and result file.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker images | grep test-app
WARNING: This output is designed for human readability. For machine-readable output, please use --format.
test-app:latest   1531c27ca46e       1.25GB          306MB   U

seva@Seva:/.../DevOps-Intro/labs/lab11/app$ ls -lh result
lrwxrwxrwx 1 seva seva 58 Apr  1 11:40 result -> /nix/store/g5kgisk0nvalziy2l0yh379f8ajgva24-nix-app.tar.gz
```

The image is relatively large because it includes base layers. The result points to a tarball in `Nix` store.


#### Build equivalent traditional Dockerfile

I build a similar image using `Docker`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker build -f Dockerfile.traditional -t traditional-app .
[+] Building 7.5s (11/11) FINISHED                                         docker:default
 => [internal] load build definition from Dockerfile.traditional                     0.1s
 => => transferring dockerfile: 209B                                                 0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                       1.7s
 => [auth] library/golang:pull token for registry-1.docker.io                        0.0s
 => [internal] load .dockerignore                                                    0.1s
 => => transferring context: 2B                                                      0.0s
 => [builder 1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db1692  0.0s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074  0.0s
 => [internal] load build context                                                    0.1s
 => => transferring context: 29B                                                     0.1s
 => CACHED [builder 2/4] WORKDIR /app                                                0.0s
 => CACHED [builder 3/4] COPY main.go .                                              0.0s
 => [builder 4/4] RUN go build -o my-app main.go                                     4.9s
 => [stage-1 1/1] COPY --from=builder /app/my-app /app                               0.0s
 => exporting to image                                                               0.5s
 => => exporting layers                                                              0.2s
 => => exporting manifest sha256:d34c9669f18d95adcc2c65bd6c5d06d1d761da3cf756edcd80  0.0s
 => => exporting config sha256:3a071160e16bbd7c545d4839350f4512d78c7e57ff5b646dbab7  0.0s
 => => exporting attestation manifest sha256:0c3efe52f73a87f4a86c9c0a4add009af51f77  0.1s
 => => exporting manifest list sha256:2db512113a6e373e8bcd841e4ab7281d2caa1916ed897  0.0s
 => => naming to docker.io/library/traditional-app:latest                            0.0s
 => => unpacking to docker.io/library/traditional-app:latest                         0.0s
```

The build completes successfully. `Docker` uses multi-stage build.


#### Compare image sizes

I compare sizes of images.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker images | grep -E traditional-app
WARNING: This output is designed for human readability. For machine-readable output, please use --format.
traditional-app:latest   2db512113a6e       3.26MB         1.24MB
```

The traditional image is smaller. It contains only the binary.


#### Test reproducibility

I rebuild the image and check hash.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix-build docker.nix --option build-repeat 2
sha256sum result
...
Running phase: fixupPhase
shrinking RPATHs of ELF executables and libraries in /nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0
shrinking /nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0/bin/app
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
checking for references to /build/ in /nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0...
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
patching script interpreter paths in /nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0
stripping (with command strip and flags -S -p) in  /nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0/bin
building '/nix/store/a93l346qp74r33jv39r1amnnw1dhdrlc-nix-app-customisation-layer.drv'...
building '/nix/store/smq1wbnhaq9frvfckd5p3658zn3viav6-excludePaths.drv'...
building '/nix/store/86fvfpilmhs8j5vn58pwbdi2c8zqfi11-layers.json.drv'...
structuredAttrs is enabled
building '/nix/store/l08qskr142dva509fj5qy2ck5zdvpa2l-nix-app-conf.json.drv'...
{
  "architecture": "amd64",
  "config": {
    "Cmd": [
      "/bin/app"
    ]
  },
  "os": "linux",
  "store_dir": "/nix/store",
  "from_image": null,
  "store_layers": [
    [
      "/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a"
    ],
    [
      "/nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0"
    ]
  ],
  "customisation_layer": "/nix/store/wmzyp3xacbw6v8381z2ybxmls02s80zg-nix-app-customisation-layer",
  "repo_tag": "nix-app:latest",
  "created": "1970-01-01T00:00:01+00:00",
  "mtime": "1970-01-01T00:00:01+00:00",
  "uid": "0",
  "gid": "0",
  "uname": "root",
  "gname": "root"
}
building '/nix/store/9z9zw7h8dvr40g387prdn9ybjqpm59m8-stream-nix-app.drv'...
building '/nix/store/91b3adzwaxdmh25a97kpa6fckclllrcr-nix-app.tar.gz.drv'...
No 'fromImage' provided
Creating layer 1 from paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
Creating layer 2 from paths: ['/nix/store/7cga005i211s26191fxv2a44x9glll4v-app-1.0']
Creating layer 3 with customisation...
Adding manifests...
Done.
/nix/store/25f3ailpbv4bqcs2z0rgs06bmgg2niki-nix-app.tar.gz
2d420b5233ccf25ac0fc6c77e9ff6de47f7287fdcd36dc7e1e55a898f89dc85f  result
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ sha256sum result
2d420b5233ccf25ac0fc6c77e9ff6de47f7287fdcd36dc7e1e55a898f89dc85f  result
```

The hash is identical between builds. This proves reproducibility.


### 2.3. Inspect Image Layers

#### Examine Nix image layers

I inspect layers of `Nix` image.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker history nix-app
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
f96f167614c8   N/A                    8.19kB    store paths: ['/nix/store/npqs36aq1f0r8ykfqb6vb583jr4qwr43-nix-app-customisation-layer']
<missing>      N/A                    1.81MB    store paths: ['/nix/store/dsvzkrb2g9ldghi27ksvcfsad7qq0yjr-app-1.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
```

The layers are based on `Nix` store paths. They are deterministic and clearly defined.


#### Compare with traditional image

I inspect layers of `Docker image`.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ docker history traditional-app
IMAGE          CREATED              CREATED BY                         SIZE      COMMENT
2db512113a6e   About a minute ago   ENTRYPOINT ["/app"]                0B        buildkit.dockerfile.v0
<missing>      About a minute ago   COPY /app/my-app /app # buildkit   2.02MB    buildkit.dockerfile.v0
```

The layers are created during build process. They include timestamps and build steps.


### Analysis: Why are Nix-built images smaller and more reproducible?

Nix images are reproducible because they use fixed store paths and deterministic builds. All dependencies are explicitly defined and hashed. There are no timestamps in layers, which removes variability. However, image size can be larger because dependencies are included explicitly. Despite that, the structure is clean and predictable. This makes Nix better for reproducibility.


### Layer structure comparison

Nix image layers correspond directly to store paths. Each layer is based on exact dependencies. Traditional Docker layers are based on build steps from Dockerfile. They depend on order of commands and caching. Nix layers are deterministic, while Docker layers may vary. This makes Nix more stable across builds.


### Practical advantages of content-addressable Docker images

Content-addressable images guarantee that the same inputs produce the same outputs. This improves reliability in CI/CD pipelines. It also simplifies debugging because builds are predictable. Teams can share identical environments without conflicts. Rollbacks are easier because previous versions are preserved. Overall, it reduces "works on my machine" problems.


## Bonus Task - Modern Nix with Flakes

### Bonus.1. Convert to Flake

#### Create a `flake.nix`

I create a `flake` configuration for the project.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ cat flake.nix
{
  description = "Reproducible Go app with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    app = pkgs.buildGoModule {
      pname = "app";
      version = "1.0";

      src = ./.;

      vendorHash = null;

      subPackages = [ "." ];
    };

  in {
    packages.${system}.default = app;

    dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
      name = "nix-app";
      tag = "latest";

      contents = [ app ];

      config = {
        Cmd = [ "/bin/app" ];
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.go
        pkgs.gopls
      ];
    };
  };
}
```

The flake defines package, Docker image and development shell. It uses pinned nixpkgs version.


#### Generate lock file

I generate a lock file for dependencies.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix flake update
```

This creates `flake.lock`. All dependencies are now fixed and reproducible.


#### Build using flake

I build the application and `Docker` image using the flake.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix build

seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix build .#dockerImages.x86_64-linux.default
```

Both builds succeed. Flake provides a unified interface for building outputs.


### Bonus.2. Test Portability

#### Commit your flake to git

I commit the flake configuration to the repository.

```bash
C:\...\DevOps-Intro> git commit -S -m "feat: add Nix flake for reproducible builds"
```

The flake is now version-controlled and can be shared.


#### Test on another machine

I build the project from `GitHub` on another machine.

```bash
user@user:/...$ nix build "github:GreatDruk/DevOps-Intro?ref=feature/lab11&dir=labs/lab11/app#default"
```

The build works without manual setup. All dependencies are fetched automatically.


#### Compare store paths

I compare build results across machines.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix build .#default
readlink -f result
warning: Git tree '/.../DevOps-Intro' is dirty
/nix/store/k3adcyb5n0dawa4d9biyadvr015asfms-app-1.0

user@user:/...$ readlink -f result
/nix/store/k3adcyb5n0dawa4d9biyadvr015asfms-app-1.0
```

The store paths are identical. This proves reproducibility across machines.


### Bonus.3. Add Development Shell

#### Add a dev shell to your flake

I define a development shell with required tools.

The shell includes Go and language server. It ensures consistent development environment.


#### Enter the dev shell

I enter the development environment.

```bash
seva@Seva:/.../DevOps-Intro/labs/lab11/app$ nix develop
```

The shell starts successfully. All required tools are available.


### Dev shell experience: Why is this better than traditional dev setups?

The dev shell provides a fully reproducible environment. All tools and versions are defined in one place. There is no need to install dependencies manually. It works the same on any machine. This reduces setup time and avoids environment issues.


### Reflection: How do Flakes improve upon traditional Nix expressions?

Flakes improve reproducibility by locking dependencies in `flake.lock`. They provide a standard project structure and clear outputs. Builds are easier to run with simple commands. Flakes also improve sharing and collaboration via Git. Overall, they make Nix more user-friendly and predictable.
