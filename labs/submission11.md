# Lab 11 — Reproducible Builds with Nix



## Task 1 — Build Reproducible Artifacts from Scratch

### Install Nix using the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

```bash
INFO nix-installer v3.17.0
...
```

### Verify Installation:

```bash
nix --version
```

```bash
nix (Determinate Nix 3.17.0) 2.33.3
```

### Test Basic Nix Usage:

```bash
nix run nixpkgs#hello
```

```bash
Hello, world!
```

### Create a lab directory:

```bash
mkdir -p labs/lab11/app
cd labs/lab11/app
```

### Create `main.go`:

```bash
nano main.go
cat main.go
```

```bash
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

### Create a Nix derivation:

```bash
touch default.nix
```

### Build your application:

```bash
nix-build
```

```bash
unpacking 'https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/%2A.tar.gz' into the Git cache...
this derivation will be built:
  /nix/store/sy0smamndbar155zambii6rklc46r83d-lab11-app.drv
these 58 paths will be fetched (166.5 MiB download, 1.2 GiB unpacked):
  /nix/store/49rnbvkp4nywgr2pqcmii0dr4sbj9zs7-apple-sdk-14.4
...
Running phase: fixupPhase
checking for references to /nix/var/nix/builds/nix-53419-2164619467/ in /nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app...
patching script interpreter paths in /nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app
/nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app
```

### Record the store path:

```bash
readlink result
```

```bash
/nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app
```

### Build again and compare:

```bash
rm result
nix-build
readlink result
```

```bash
/nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app

/nix/store/vy519fkkq63h73lgpfs89prd7m1ch1mp-lab11-app
```

### Create a `Dockerfile`:

```bash
nano Dockerfile
cat Dockerfile
```

```bash
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

### Build twice:

```bash
docker build -t test-app .
docker build -t test-app .
```

```bash
[+] Building 183.1s (10/10) FINISHED                                                                                                                                                              docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                              0.0s
 => => transferring dockerfile: 110B                                                                                                                                                                              0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                                                                                                                                                   11.2s
 => [auth] library/golang:pull token for registry-1.docker.io                                                                                                                                                     0.0s
 => [internal] load .dockerignore                                                                                                                                                                                 0.0s
 => => transferring context: 2B                                                                                                                                                                                   0.0s
 => [internal] load build context                                                                                                                                                                                 0.0s
 => => transferring context: 218B                                                                                                                                                                                 0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c5ccb62d181034df7f02                                                                                            169.4s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c5ccb62d181034df7f02                                                                                              0.0s
 => => sha256:57dbbf9ce594cc754a73fd4187ffcab90bc86d0666530017aa2cd0361f85d84c 126B / 126B                                                                                                                        0.4s
 => => sha256:90fc70e12d60da9fe07466871c454610a4e5c1031087182e69b164f64aacd1c4 66.29MB / 66.29MB                                                                                                                151.1s
 => => sha256:5ac3f7121b9240f61d416dba8be2c96da4ffe9fe1f25831725071946bb7fc54f 86.38MB / 86.38MB                                                                                                                167.5s
 => => sha256:c9d3572a68af0b860060b7ea84adfa8406fa20cfd1337c947dfb661aa965eee7 64.36MB / 64.36MB                                                                                                                147.1s
 => => sha256:193c44006e77abbadfdd7be72b4ab6d7a5c08640ef575970f722b798ee7800ac 23.60MB / 23.60MB                                                                                                                 53.2s
 => => sha256:106abeaee908db66722312b3379ae398e2bcc5b2fdad0cc248509efa14a819ff 48.31MB / 48.31MB                                                                                                                 92.3s
 => => extracting sha256:106abeaee908db66722312b3379ae398e2bcc5b2fdad0cc248509efa14a819ff                                                                                                                         0.5s
 => => extracting sha256:193c44006e77abbadfdd7be72b4ab6d7a5c08640ef575970f722b798ee7800ac                                                                                                                         0.2s
 => => extracting sha256:c9d3572a68af0b860060b7ea84adfa8406fa20cfd1337c947dfb661aa965eee7                                                                                                                         0.7s
 => => extracting sha256:5ac3f7121b9240f61d416dba8be2c96da4ffe9fe1f25831725071946bb7fc54f                                                                                                                         0.8s
 => => extracting sha256:90fc70e12d60da9fe07466871c454610a4e5c1031087182e69b164f64aacd1c4                                                                                                                         1.2s
 => => extracting sha256:57dbbf9ce594cc754a73fd4187ffcab90bc86d0666530017aa2cd0361f85d84c                                                                                                                         0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                         0.0s
 => [2/4] WORKDIR /app                                                                                                                                                                                            0.1s
 => [3/4] COPY main.go .                                                                                                                                                                                          0.0s
 => [4/4] RUN go build -o app main.go                                                                                                                                                                             1.5s
 => exporting to image                                                                                                                                                                                            0.6s
 => => exporting layers                                                                                                                                                                                           0.5s
 => => exporting manifest sha256:ded36238d0b5ebc6b6c01946b418fe43323f532f5770ad2da8dca446c0ef5869                                                                                                                 0.0s
 => => exporting config sha256:d46d1887f01fa960b62ec22e5243593f8519de78f2216d0f82087b52e9f91061                                                                                                                   0.0s
 => => exporting attestation manifest sha256:a47eea3694f305bc9a217948b5a386a966a59cb5a86d158025b545644861d83e                                                                                                     0.0s
 => => exporting manifest list sha256:27a6de694396346ca7bcf339e45b44afd95625faa398c331b1e818952605259f                                                                                                            0.0s
 => => naming to docker.io/library/test-app:latest                                                                                                                                                                0.0s
 => => unpacking to docker.io/library/test-app:latest 

[+] Building 0.9s (9/9) FINISHED                                                                                                                                                                  docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                              0.0s
 => => transferring dockerfile: 110B                                                                                                                                                                              0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                                                                                                                                                    0.8s
 => [internal] load .dockerignore                                                                                                                                                                                 0.0s
 => => transferring context: 2B                                                                                                                                                                                   0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c5ccb62d181034df7f02                                                                                              0.0s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c5ccb62d181034df7f02                                                                                              0.0s
 => [internal] load build context                                                                                                                                                                                 0.0s
 => => transferring context: 29B                                                                                                                                                                                  0.0s
 => CACHED [2/4] WORKDIR /app                                                                                                                                                                                     0.0s
 => CACHED [3/4] COPY main.go .                                                                                                                                                                                   0.0s
 => CACHED [4/4] RUN go build -o app main.go                                                                                                                                                                      0.0s
 => exporting to image                                                                                                                                                                                            0.0s
 => => exporting layers                                                                                                                                                                                           0.0s
 => => exporting manifest sha256:ded36238d0b5ebc6b6c01946b418fe43323f532f5770ad2da8dca446c0ef5869                                                                                                                 0.0s
 => => exporting config sha256:d46d1887f01fa960b62ec22e5243593f8519de78f2216d0f82087b52e9f91061                                                                                                                   0.0s
 => => exporting attestation manifest sha256:4c86c10699263c3a8d0b2ccc1e2fdfa17f75aa7fe3121e1abf536102e4ae8c51                                                                                                     0.0s
 => => exporting manifest list sha256:0b21f55bc88666906abedd42e89ddf820aecd51f80e7f72706d1146224ba71fd                                                                                                            0.0s
 => => naming to docker.io/library/test-app:latest                                                                                                                                                                0.0s
 => => unpacking to docker.io/library/test-app:latest 
```

### Reflection

- **No "works on my machine" problems**

    - **pip**: Spend time debugging why the app works for me, but not for others
    - **Nix**: all developers have the same environment from the first launch

- **Dependency versioning**

    - **pip**: pip freeze, only direct dependencies
    - **Nix**: Nix locks everything - including 
    Python version and all transitive dependencies

- **Clean environments**

    - **pip**: virtualenv sometimes clashed with system packages
    - **Nix**: complete isolation, no conflicts

- **Caching of assemblies**

    - **pip**: pip install from scratch
    - **Nix**: Nix caches by content hash - repeated builds are instant

- **Documentation in the code**

    - **pip**: it was necessary to write a `README` about the versions
    - **Nix**: `default.nix` itself is the documentation



## Task 2 — Reproducible Docker Images with Nix

### Run the container:

```bash
docker run docker.io/library/test-app:latest
```

### Check Nix-built image size:

```bash
ls -lh result
```

```bash
lrwxr-xr-x@ 1 miraladutska  staff    56B Mar  9 18:47 result -> /nix/store/4w6i1qx2k6g5bb7m2i2h1gfhk6kk7hnr-hello-2.12.2
```

### Create a minimal `Dockerfile.traditional`:

```bash
nano Dockerfile.traditional
cat Dockerfile.traditional
```

```bash
FROM scratch
COPY --from=golang:1.22 /path/to/binary /app
ENTRYPOINT ["/app"]
```

### Build it:

```bash
docker build -f Dockerfile.traditional -t traditional-app .
```

### Build the Nix image twice on different days:

```bash
docker build -f Dockerfile.traditional -t traditional-app .
```

```bash
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
0b21f55bc886   23 minutes ago   RUN /bin/sh -c go build -o app main.go # bui…   31.6MB    buildkit.dockerfile.v0
<missing>      23 minutes ago   COPY main.go . # buildkit                       12.3kB    buildkit.dockerfile.v0
<missing>      23 minutes ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      13 months ago    WORKDIR /go                                     4.1kB     buildkit.dockerfile.v0
<missing>      13 months ago    RUN /bin/sh -c mkdir -p "$GOPATH/src" "$GOPA…   16.4kB    buildkit.dockerfile.v0
<missing>      13 months ago    COPY /target/ / # buildkit                      263MB     buildkit.dockerfile.v0
<missing>      13 months ago    ENV PATH=/go/bin:/usr/local/go/bin:/usr/loca…   0B        buildkit.dockerfile.v0
<missing>      13 months ago    ENV GOPATH=/go                                  0B        buildkit.dockerfile.v0
<missing>      13 months ago    ENV GOTOOLCHAIN=local                           0B        buildkit.dockerfile.v0
<missing>      13 months ago    ENV GOLANG_VERSION=1.22.12                      0B        buildkit.dockerfile.v0
<missing>      13 months ago    RUN /bin/sh -c set -eux;  apt-get update;  a…   248MB     buildkit.dockerfile.v0
<missing>      2 years ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   200MB     buildkit.dockerfile.v0
<missing>      2 years ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   52.4MB    buildkit.dockerfile.v0
<missing>      2 years ago      # debian.sh --arch 'arm64' out/ 'bookworm' '…   155MB     debuerreotype 0.15
```

### `Dockerfile` vs Nix `docker.nix`

| Aspect | Traditional Dockerfile | Nix dockerTools |
|--------|------------------|-----------------------|
| Base images | `python:3.9-slim` (changes over time) | No base image (pure derivations) |
| Timestamps | Different on each build | Fixed or deterministic
| Package installation | apt-get install + pip install | Declarative description in contents |
| Package installation | pip install at build time | Nix store paths (immutable) |
| Reproducibility | Same Dockerfile -> Different images | Same `docker.nix` -> Identical images |
| Build Caching | Layer-based (breaks on timestamp) | Content-addressable (perfect caching) |
| Image Size | 391.45MB with full base image | 1.6GB with minimal closure |
| Portability | Requires Docker | Requires Nix (then loads to Docker) |
| Security | Base image vulnerabilities | Minimal dependencies, easier auditing |

### Image size comparison with analysis

- **Dockerfile**: 391.45MB
- **Nix dockerTools**: 1.6GB

**Nix image**:

- There is no base image with extra OS files
- Only the minimum necessary dependencies
- Python is included as part of closure, not as a separate layer

### Analysis

- Timestamps

    - Each Docker layer gets a timestamp of creation
    - Even with the same content, timestamps are different -> different hashes

- `apt-get install`

    - Downloads the "latest" versions of packages from repositories
    - Repositories are updated -> packages are changed

- `pip install`

    - Even with pinned versions, downloads wheel files
    - Wheels can be rebuilt with different optimizations

- Build context

    - `.dockerignore` can skip different files
    - The order of copying affects the layers

- Network

    - Different mirrors may give different versions
    - CDN caching may affect downloaded files

### Reflection

- **Automate reproducibility testing**

    - **pip**: Catch problems before they get into the prod
    - **Nix**: In CI, check that nix-build gives the same hash

- **Document the dependencies in one place**

    - **pip**: Dependencies in `requirements.txt` + `Dockerfile` + `README`
    - **Nix**: All in one declarative file

- **Use assembly caching**

    - **pip**: Each build downloads everything as a new
    - **Nix**: Binary cache speeds up builds

### Practical scenarios where Nix's reproducibility matters

- **CI/CD Pipelines**: The deployment should be predictable. If it's assembled today and it's working, tomorrow it should work the same way

- **Security Audits**: For compliance, need to know the exact versions of the entire stack, including transitive dependencies

- **Rollbacks**: Instant rollback to any previous version, even if it was not launched in the registry

- **Multi-team collaboration**: "Works on my machine" disappears. What works on local - works for everyone

- **Release engineering**: Legal requirements for long-term support (LTS) releases
- 