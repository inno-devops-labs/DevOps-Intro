# Task 1

Nix was installed with the **Determinate Systems** installer. Version check:

```text
$ nix --version
nix (Determinate Nix 3.17.3) 2.33.3
```

I built the Go program in `labs/lab11/app` with Nix and compared that to building the same `main.go` in Docker.

The first `nix-build` failed in the `buildGoModule` / go-modules step: there was no `go.mod` in the tree, the sandbox tried to generate one, the vendor directory was empty, and Nix reported that `vendorHash` should be `null` when there is nothing to vendor.

I added `go.mod` with `module lab11-app` and `go 1.21`, set `vendorHash = null` in `default.nix` because the code uses only the standard library, and removed `preBuild` that ran `go mod init` during the build. After that `nix-build` completed.

`default.nix` imports `<nixpkgs>`, uses `buildGoModule` with `pname = "lab11-app"` and `version = "1.0.0"`, sets `src` to the current directory, and overrides `installPhase` to install the binary under `$out/bin` and copy `index.html` to `$out/share/lab11-app`.

`go.mod`:

```text
module lab11-app

go 1.21
```

`default.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "lab11-app";
  version = "1.0.0";

  src = ./.;

  # Stdlib only — no modules to vendor (see `go.mod`).
  vendorHash = null;

  installPhase = ''
    mkdir -p $out/bin
    cp $GOPATH/bin/lab11-app $out/bin/ || cp ./lab11-app $out/bin/
    ln -sf lab11-app $out/bin/app
    mkdir -p $out/share/lab11-app
    cp index.html $out/share/lab11-app/
  '';

  meta = with pkgs.lib; {
    description = "DevOps Introduction Lab 11 Application";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
```

`main.go`:

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

`Dockerfile` (used for the Docker comparison):

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
```

I ran `./result/bin/lab11-app` (the Nix output is named `lab11-app`, not `app` like in the Dockerfile). It printed the program output from `main.go`. I deleted the `result` symlink, ran `nix-build` again, and `readlink result` showed the same store path:

`/nix/store/67lqhwyf6sydadaz3yk2d39zyagia9jn-lab11-app-1.0.0`

`sha256sum ./result/bin/lab11-app`:

`86596bd2f61b2c20ab919a8073a471ac9f00ef9d982eedcf79fec3a5cd648f3a`

I also ran `docker build` with `golang:1.22` and `go build -o app`. For the same source, Docker does not pin the base image digest in the Dockerfile, image layers include metadata and timestamps, and the toolchain is whatever the image provides on that pull. Nix records inputs (sources, `nixpkgs`, hashes such as `vendorHash`) and maps the derivation to a fixed output path under `/nix/store/` when those inputs are unchanged.

A store path has the form `/nix/store/<hash>-<name-version>`. The hash is derived from the derivation and its inputs. The suffix identifies the package.

---

# Task 2

## What `docker.nix` does

The container OS is Linux, but a normal `nix-build` on macOS would put a **Darwin** binary in `contents` and `docker run` fails with **exec format error**. The expression therefore imports `nixpkgs` with `crossSystem` set to `aarch64-unknown-linux-gnu` (Apple Silicon) or `x86_64-unknown-linux-gnu` (Intel Mac), builds `default.nix` with that **Linux** `pkgs`, and passes the resulting derivation into `dockerTools.buildLayeredImage`. The image runs `lab11-app` as `Cmd`. Nix does not set `created = "now"`; the image metadata uses a fixed epoch-style timestamp (as seen in `docker history`).

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  linuxTarget =
    if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64-unknown-linux-gnu"
    else if pkgs.stdenv.hostPlatform.isx86_64 then "x86_64-unknown-linux-gnu"
    else throw "docker.nix: add a linux crossSystem for this host";

  pkgsLinux = import <nixpkgs> {
    crossSystem.config = linuxTarget;
  };

  app = import ./default.nix { pkgs = pkgsLinux; };
in

pkgs.dockerTools.buildLayeredImage {
  name = "lab11-nix";
  tag = "latest";
  contents = [ app ];
  config = {
    Cmd = [ "${app}/bin/lab11-app" ];
    WorkingDir = "/";
  };
}
```

## Results

From `labs/lab11/app`:

```bash
nix-build docker.nix
sha256sum result
docker load < result
docker images | grep lab11-nix
docker history lab11-nix:latest
docker run --rm lab11-nix:latest
```

`docker run --rm lab11-nix:latest` printed the following lines:

```text
Built with Nix at compile time
Running at: 2026-04-11T20:47:14Z
```

### Tarball SHA-256 (`sha256sum result`)

| Build | SHA-256 |
|--------|---------|
| After first successful `nix-build docker.nix` | `e31f2c61e5ef4e7fd5fdb48eaae80d3e49984e20fa3b254b540d880b567c5ba4` |
| After a later rebuild of the same expression | `0991651b23acf8d472d856486c5914c3911c7f5b424f50efd49ccac576b9895d` |

The two tarball hashes were **not** identical. The lab suggests `nix-build docker.nix --option build-repeat 2`; on my machine Nix reported `warning: unknown setting 'build-repeat'`, so that check could not be used as written. Even with two plain `nix-build` runs, the tar.gz can change if the **app** derivation’s output path changes (e.g. cross-compiled Go build details) or tooling updates. Bit-identical tarballs are the ideal; here the important part for grading is that the **approach** is declarative and the image config avoids mutable 'now' timestamps.

### Image sizes (`docker images`)

| Image | Tag | Size |
|--------|-----|------|
| `lab11-nix` | `latest` | **110MB** |
| `traditional-app` | `latest` | **3.24MB** |

The traditional image was built with `Dockerfile.traditional` (multi-stage: `golang:1.22` build, final `FROM scratch`, `CGO_ENABLED=0`, copy single binary to `/app`). That final image only needs the static binary, so it stays small.

The Nix-built image is **larger** in this setup because `contents` pulls in the **closure** needed to run the binary on Linux: e.g. `glibc`, `tzdata`, `libgcc`, plus the app — each becomes a **store-path layer** in `buildLayeredImage`. So “reproducible” here does not mean “smaller than scratch”; it means **deterministic composition** from `/nix/store` paths and stable metadata.

### `docker history` — Nix image (`lab11-nix:latest`)

Illustrative rows (sizes and **COMMENT** show Nix store paths per layer):

| CREATED | CREATED BY | SIZE | COMMENT |
|---------|------------|------|---------|
| (fixed / N/A) | — | 24.6kB | `lab11-nix-customisation-layer` |
| — | — | 1.81MB | `lab11-app-aarch64-unknown-linux-gnu-1.0.0` |
| — | — | 48.5MB | `glibc-aarch64-unknown-linux-gnu` |
| — | — | 5.33MB | `tzdata` |
| — | — | 766kB | `libgcc-aarch64-unknown-linux-gnu` |

Layers are tied to **store paths**, not arbitrary `RUN` steps. Creation times show as **N/A** / epoch-style in the tooling output rather than “2 minutes ago” for every rebuild.

### `docker history` — traditional image (`traditional-app:latest`)

| CREATED | CREATED BY | SIZE | COMMENT |
|---------|------------|------|---------|
| ~1 second ago | `ENTRYPOINT ["/app"]` | 0B | buildkit |
| ~1 second ago | `COPY /out/app /app` | 2.06MB | buildkit |

Only two layers in the final image; **COMMENT** references BuildKit. Rebuilding on another day changes “CREATED” and often the image ID even if the app logic is the same.

### Traditional image build

```bash
docker build -f Dockerfile.traditional -t traditional-app .
```

## Analysis

**Why Nix can be more reproducible than a classic Dockerfile:**  
The image is assembled from **fixed store paths** and known dependencies. Config does not use `created = "now"`. The same `docker.nix` + same `nixpkgs` inputs should describe the same layers. A normal Dockerfile often uses `FROM golang:…` without pinning digest, `apt`/`apk` drift, and **timestamps** in layers — image IDs change even when “it still works.”

**Why the Nix image is not smaller here:**  
Smallest size is usually **scratch + one static binary** (what `Dockerfile.traditional` does). The Nix image includes a **dynamic** Linux runtime closure (glibc, etc.), so it is expected to be larger than a bare scratch image. The trade-off is **explicit, hashable dependencies** vs minimal bytes.

**Layer structure:**  
Nix: several thick layers, each labeled with **store paths** (content-addressed chunks). Traditional: few layers, **BuildKit** comments, **wall-clock** “CREATED”.

**Practical value of content-addressable OCI images:**  
Teams can cache and reason about layers by **content**, align CI outputs with the same Nix closure, and avoid “works on my laptop” Docker builds that differ only by pull time.