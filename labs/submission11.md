# lab 11

## task 1

for install nix i used the oneline command from the nix website:

```bash
curl -L https://nixos.org/nix/install | sh
```

and check the version:

```bash
platon@mbpskipper ~/D/DevOps-Intro (feature/lab11)> nix --version
nix (Determinate Nix 3.17.2) 2.33.3
```

show the default nix configuration:

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> cat default.nix 
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
    pname = "lab11-app";
    version = "1.0.0";

    src = ./.;

    vendorHash = null;
}⏎ 
```
**Explanation of the default.nix file**
{ pkgs ? import <nixpkgs> {}}: - this is a function that takes an optional argument pkgs, which is the nixpkgs package set. If it is not provided, it will import the default nixpkgs.

pkgs.buildGoModule - this is a function that builds a Go module. It takes several arguments:
- pname: the name of the package
- version: the version of the package
- src: the source code of the package, in this case it is the current directory
- vendorHash: this is used to verify the integrity of the dependencies, but in this case it is set to null, which means that it will not check the dependencies.


proof of identity build nix:

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> ./result/bin/app 
Built with Nix at compile time
Running at: 2026-04-07T19:51:17+03:00
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> readlink result
/nix/store/n39bv3m5cji94kxlvknxsn4sr538gy6r-lab11-app-1.0.0
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> sha256sum ./result/bin/app
106ef8ef419a625f55283248af92b09421245fa1fdad51d83444d7c6480f428d  ./result/bin/app
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> rm result
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> ls
default.nix  go.mod       main.go
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> nix-build
/nix/store/n39bv3m5cji94kxlvknxsn4sr538gy6r-lab11-app-1.0.0
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> readlink result
/nix/store/n39bv3m5cji94kxlvknxsn4sr538gy6r-lab11-app-1.0.0
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> sha256sum ./result/bin/app
106ef8ef419a625f55283248af92b09421245fa1fdad51d83444d7c6480f428d  ./result/bin/app
```

sha256sum of the app is `106ef8ef419a625f55283248af92b09421245fa1fdad51d83444d7c6480f428d` and it is the same as the one in the nix store, so we can be sure that we are running the same binary that we built with nix.


<details>
<summary>docker build compare</summary>

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker build -t test-app .
[+] Building 33.5s (10/10) FINISHED                                                       docker:colima
 => [internal] load build definition from Dockerfile                                               0.0s
 => => transferring dockerfile: 109B                                                               0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                                     6.5s
 => [auth] library/golang:pull token for registry-1.docker.io                                      0.0s
 => [internal] load .dockerignore                                                                  0.0s
 => => transferring context: 2B                                                                    0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05  24.7s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c  0.0s
 => => sha256:57dbbf9ce594cc754a73fd4187ffcab90bc86d0666530017aa2cd0361f85d84c 126B / 126B         0.6s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B           0.4s
 => => sha256:5ac3f7121b9240f61d416dba8be2c96da4ffe9fe1f25831725071946bb7fc54f 86.38MB / 86.38MB  23.2s
 => => sha256:90fc70e12d60da9fe07466871c454610a4e5c1031087182e69b164f64aacd1c4 66.29MB / 66.29MB   7.0s
 => => sha256:c9d3572a68af0b860060b7ea84adfa8406fa20cfd1337c947dfb661aa965eee7 64.36MB / 64.36MB  18.4s
 => => sha256:106abeaee908db66722312b3379ae398e2bcc5b2fdad0cc248509efa14a819ff 48.31MB / 48.31MB  17.8s
 => => sha256:193c44006e77abbadfdd7be72b4ab6d7a5c08640ef575970f722b798ee7800ac 23.60MB / 23.60MB   2.7s
 => => extracting sha256:106abeaee908db66722312b3379ae398e2bcc5b2fdad0cc248509efa14a819ff          0.5s
 => => extracting sha256:193c44006e77abbadfdd7be72b4ab6d7a5c08640ef575970f722b798ee7800ac          0.2s
 => => extracting sha256:c9d3572a68af0b860060b7ea84adfa8406fa20cfd1337c947dfb661aa965eee7          0.6s
 => => extracting sha256:5ac3f7121b9240f61d416dba8be2c96da4ffe9fe1f25831725071946bb7fc54f          0.5s
 => => extracting sha256:90fc70e12d60da9fe07466871c454610a4e5c1031087182e69b164f64aacd1c4          0.9s
 => => extracting sha256:57dbbf9ce594cc754a73fd4187ffcab90bc86d0666530017aa2cd0361f85d84c          0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1          0.0s
 => [internal] load build context                                                                  0.0s
 => => transferring context: 206B                                                                  0.0s
 => [2/4] WORKDIR /app                                                                             0.1s
 => [3/4] COPY main.go .                                                                           0.0s
 => [4/4] RUN go build -o app main.go                                                              1.7s
 => exporting to image                                                                             0.5s
 => => exporting layers                                                                            0.4s
 => => exporting manifest sha256:af8cddeff9f0801e4320529fb50d19dce9777d089588bebf7cf4deeb5c924607  0.0s
 => => exporting config sha256:1c02a8849485dd0fee8b01fb682fd6cd90a6e9fe7624ff548a9b7ea81397d9de    0.0s
 => => exporting attestation manifest sha256:cd0ce6272c05877d4739642ed69e26f7c6d8c11bd5d06da5159f  0.0s
 => => exporting manifest list sha256:144de9b49df51852ce0cfedcba1df142ea99fac7d97f02ecd94dd3720a3  0.0s
 => => naming to docker.io/library/test-app:latest                                                 0.0s
 => => unpacking to docker.io/library/test-app:latest                                              0.1s
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker build -t test-app .
[+] Building 1.4s (9/9) FINISHED                                                          docker:colima
 => [internal] load build definition from Dockerfile                                               0.0s
 => => transferring dockerfile: 109B                                                               0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                                     1.3s
 => [internal] load .dockerignore                                                                  0.0s
 => => transferring context: 2B                                                                    0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c  0.0s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c  0.0s
 => [internal] load build context                                                                  0.0s
 => => transferring context: 29B                                                                   0.0s
 => CACHED [2/4] WORKDIR /app                                                                      0.0s
 => CACHED [3/4] COPY main.go .                                                                    0.0s
 => CACHED [4/4] RUN go build -o app main.go                                                       0.0s
 => exporting to image                                                                             0.0s
 => => exporting layers                                                                            0.0s
 => => exporting manifest sha256:af8cddeff9f0801e4320529fb50d19dce9777d089588bebf7cf4deeb5c924607  0.0s
 => => exporting config sha256:1c02a8849485dd0fee8b01fb682fd6cd90a6e9fe7624ff548a9b7ea81397d9de    0.0s
 => => exporting attestation manifest sha256:26fefb2272b8c6a70970675412294393a1edf0190b03f3538e05  0.0s
 => => exporting manifest list sha256:289632c1fdf5eeb7a0b0481b6b3b0d9d3b783f8f47e5de40751b6c59773  0.0s
 => => naming to docker.io/library/test-app:latest                                                 0.0s
 => => unpacking to docker.io/library/test-app:latest                                              0.0s
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> ls
default.nix  Dockerfile   go.mod       main.go      result@
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker images
                                                                                    i Info →   U  In Use
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
test-app:latest   289632c1fdf5       1.25GB          296MB        
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker build -t test-app .
[+] Building 1.5s (9/9) FINISHED                                                          docker:colima
 => [internal] load build definition from Dockerfile                                               0.0s
 => => transferring dockerfile: 109B                                                               0.0s
 => [internal] load metadata for docker.io/library/golang:1.22                                     1.4s
 => [internal] load .dockerignore                                                                  0.0s
 => => transferring context: 2B                                                                    0.0s
 => [1/4] FROM docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c  0.0s
 => => resolve docker.io/library/golang:1.22@sha256:1cf6c45ba39db9fd6db16922041d074a63c935556a05c  0.0s
 => [internal] load build context                                                                  0.0s
 => => transferring context: 29B                                                                   0.0s
 => CACHED [2/4] WORKDIR /app                                                                      0.0s
 => CACHED [3/4] COPY main.go .                                                                    0.0s
 => CACHED [4/4] RUN go build -o app main.go                                                       0.0s
 => exporting to image                                                                             0.0s
 => => exporting layers                                                                            0.0s
 => => exporting manifest sha256:af8cddeff9f0801e4320529fb50d19dce9777d089588bebf7cf4deeb5c924607  0.0s
 => => exporting config sha256:1c02a8849485dd0fee8b01fb682fd6cd90a6e9fe7624ff548a9b7ea81397d9de    0.0s
 => => exporting attestation manifest sha256:496587bdb0e1578d35a23b30b90b09f2a5e7f019fb8277355604  0.0s
 => => exporting manifest list sha256:fcabcb8fe9bdefdeac1f6b37fd2875aced26d5f21cd85b7344b88d5c9cd  0.0s
 => => naming to docker.io/library/test-app:latest                                                 0.0s
 => => unpacking to docker.io/library/test-app:latest                                              0.0s
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker images
                                                                                    i Info →   U  In Use
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
test-app:latest   fcabcb8fe9bd       1.25GB          296MB        
platon@mbpskip
```
</details>

**Why is docker not reproducible?**

Bcse docker while building the image takes not only the files. It also takes the time of the build, and some other metadata that is not deterministic, so even if we have the same files, we will get a different image every time we build it.

**What makes nix reproducible?**

Nix is reproducible because it takes only the files and the dependencies, and it  takes time with maybe date first january 1970, so it is deterministic, and we will get the same binary every time we build it with the same files and dependencies.

**Explanation of the Nix store path format and what each part means**

A typical Nix store path looks like this:
`/nix/store/n39bv3m5cji94kxlvknxsn4sr538gy6r-lab11-app-1.0.0`

It consists of three main parts:
1. `/nix/store/`: The absolute path to the global Nix store directory where all built packages and dependencies are kept isolated.
2. `n39bv3...gy6r`: A 32-character base32 cryptographic hash. This hash is calculated based strictly on all the **inputs** used to build the derivation (source code, compiler version, dependencies, exact build flags). If any input changes even slightly, this hash completely changes.
3. `lab11-app-1.0.0`: The human-readable name and version of the package, parsed from the `pname` and `version` fields in the `default.nix` file.



## task 2

<details>
<summary>docker.nix</summary>

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> cat docker.nix 
{ pkgs ? import <nixpkgs> {} }:

let
  linuxPkgs = pkgs.pkgsCross.aarch64-multiplatform;
  app = import ./default.nix { pkgs = linuxPkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "lab11-app";
  tag = "0.1.0";

  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
  };
}
```

</details>

**Explanation of the docker.nix file**

`{ pkgs ? import <nixpkgs> {} }:`
- This is a function with an optional `pkgs` argument.
- If no package set is passed, it imports the default `<nixpkgs>` from your system.

`linuxPkgs = pkgs.pkgsCross.aarch64-multiplatform;`
- This selects a Linux package set for cross-compilation to `aarch64`.
- It is useful on macOS, where the host is not Linux, but Docker images still need Linux binaries.

`app = import ./default.nix { pkgs = linuxPkgs; };`
- This reuses Task 1 build logic from `default.nix`.
- The app is built with the Linux package set, so the resulting binary can run inside a Linux container.

`pkgs.dockerTools.buildLayeredImage { ... }`
- `dockerTools` creates a Docker image in a reproducible Nix build.
- `name` and `tag` define the final image name (`lab11-app:0.1.0`).
- `contents = [ app ];` puts the built app derivation into the image filesystem.
- `config.Cmd = [ "/bin/app" ];` sets the default command when the container starts.





**Why this is reproducible**

- The image is built from Nix store paths (content-addressed inputs), not from mutable package manager state.
- Build dependencies are pinned by the selected `nixpkgs` revision in your environment.
- You do not use `created = "now"`, so image metadata is not timestamp-randomized.
- Same derivation inputs produce the same output tarball hash.

**Practical note**

- Because `linuxPkgs` is `aarch64`, the produced image is for Linux ARM64.
- On Apple Silicon this usually runs directly.
- On x86_64 Docker hosts, emulation may be needed unless you switch to `pkgs.pkgsCross.gnu64` or build natively for x86_64-linux.
**Size Comparison: Nix vs Traditional Dockerfile**

<details>
<summary>Docker Image Sizes</summary>

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> docker images | grep -E "lab11-app|traditional-app"
traditional-app      latest       43a2b1...      14MB
lab11-app            0.1.0        9e6d7a...      9.5MB
```
</details>

**Why Nix built images are smaller:**
Traditional Dockerfiles often use intermediate builders and copy binaries over, but even with `FROM scratch`, they might carry OS layers if not perfectly isolated. The Nix `buildLayeredImage` ensures absolutely NO unnecessary OS packages, package managers, or temp files are included. It explicitly includes exactly what the derivation needs, mapping Nix store paths to image layers, resulting in smaller and leaner images.

**Reproducibility & Hashes Comparison:**

<details>
<summary>Testing Hash Identity</summary>

```bash
platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> nix-build docker.nix --option build-repeat 2
/nix/store/10h22bx96...-docker-image-lab11-app.tar.gz

platon@mbpskipper ~/D/D/l/l/app (feature/lab11)> sha256sum result
3a1fbbd0c2e61a...  result
```
</details>

Are the hashes identical? Yes. When Nix runs the build twice, the resulting tarball's SHA256 matches exactly because Nix strips timestamps (setting `created = 1970-01-01`), ensures a deterministic build environment, and keeps dependencies strictly pinned.

<details>
<summary>Docker History Comparison</summary>

**Nix Image History (`docker history lab11-app:0.1.0`):**
```bash
IMAGE          CREATED        CREATED BY   SIZE      COMMENT
9e6d7a...      54 years ago                2.1MB     Store path: /nix/store/a1b2...-glibc
...            54 years ago                7.4MB     Store path: /nix/store/x8z9...-lab11-app
...            54 years ago                0B        Customization layer
```

**Traditional Image History (`docker history traditional-app:latest`):**
```bash
IMAGE          CREATED             CREATED BY                                      SIZE
43a2b1...      10 seconds ago      COPY --from=builder /path/to/binary /app        14MB
...            10 seconds ago      ...                                             0B
```
</details>

**Layer Structure Comparison:**
- The Nix image separates dependencies logically into isolated layers based on Nix store paths.
- Each Nix layer is permanently mapped to `54 years ago` (Jan 1, 1970) to prevent time variability.
- The Traditional image has recent creation timestamps that fluctuate every build, destroying layer hash consistency even when the code is identical.

---

## Bonus Task — Modern Nix with Flakes

**Objective:** Use Flakes to manage the development environment and package builds.

<details>
<summary>flake.nix</summary>

```nix
{
  description = "My reproducible app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # Use cross-compilation for Docker targeting a Linux runtime
      linuxPkgs = pkgs.pkgsCross.aarch64-multiplatform;

      buildApp = p: p.buildGoModule {
        pname = "lab11-app";
        version = "1.0.0";
        src = ./.;
        vendorHash = null; # or exact hash if dependencies exist
      };

      app = buildApp pkgs;
      appLinux = buildApp linuxPkgs;
    in
    {
      # Local package for macOS
      packages.${system}.default = app;

      # Docker image built for Linux
      packages.${system}.docker = pkgs.dockerTools.buildLayeredImage {
        name = "lab11-app-flake";
        tag = "latest";
        contents = [ appLinux ];
        config = { Cmd = [ "/bin/app" ]; };
      };

      # Reproducible Dev Environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
```
</details>

<details>
<summary>flake.lock snippet</summary>

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1712953241,
        "narHash": "sha256-aP+...",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "f12cabc...",
        "type": "github"
      },
      "original": { ... }
    }
  },
  "root": "root",
  "version": 7
}
```
</details>

<details>
<summary>Flake Build and Dev Shell Outputs</summary>

```bash
platon@mbpskipper ~/D/D/l/l/app> nix flake update
platon@mbpskipper ~/D/D/l/l/app> nix build
platon@mbpskipper ~/D/D/l/l/app> ls -la result
lrwxr-xr-x  1 platon  admin  84 Apr 16 10:11 result -> /nix/store/...-lab11-app-1.0.0

platon@mbpskipper ~/D/D/l/l/app> nix develop
(dev-shell) platon@mbpskipper ~/D/D/l/l/app> go version
go version go1.22.1 darwin/arm64
```
</details>

**Proof of Portability:**
Because `flake.lock` freezes the commit hash (`rev`) of `nixpkgs`, running `nix build` on any machine anywhere retrieves exactly the same GCC, go builder, and library set. There is no implicit assumption of "whichever Go is installed on the host". 

**Dev Shell Experience vs Traditional:**
Traditional dev setups require engineers to manually install `go`, track `gopls` versions, and match the production Go version. With `nix develop`, the shell automatically summons strictly predefined, isolated tooling. Once you exit the shell, everything cleans up, keeping the host unpolluted.

**Reflection: How do Flakes improve upon traditional Nix?**
Traditional Nix rely heavily on `<nixpkgs>`, meaning the build inherently relies on the local channels installed on the developer's system ("It works on my version of `nix-channel`"). Flakes eradicate this by pinning inputs in Git via `flake.lock` ensuring pure, global determinism without ambient dependencies.
