# Lab 11 Submission — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### 1.1 Nix Installation and Basic Usage

Nix was installed with the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Important install result:

```text
Nix was installed successfully!
To get started using Nix, open a new shell or run `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
```

Command:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix --version
```

Output:

```text
nix (Determinate Nix 3.17.3) 2.33.3
```

Command:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix --extra-experimental-features 'nix-command flakes' run nixpkgs#hello
```

Output:

```text
these 5 paths will be fetched (57.1 KiB download, 36.3 MiB unpacked):
  /nix/store/jms7zxzm7w1whczwny5m3gkgdjghmi2r-glibc-2.42-51
  /nix/store/10s5j3mfdg22k1597x580qrhprnzcjwb-hello-2.12.3
  /nix/store/1ga782ml07vy0h503ac4cin0h8d7q6yh-libidn2-2.3.8
  /nix/store/p7jg95rzvfalb95k3mskk0jqxc9d724n-libunistring-1.4.1
  /nix/store/vpxblivamvic1p5r5zny934jvg33m50r-xgcc-15.2.0-libgcc
copying path '/nix/store/vpxblivamvic1p5r5zny934jvg33m50r-xgcc-15.2.0-libgcc' from 'https://install.determinate.systems'...
copying path '/nix/store/p7jg95rzvfalb95k3mskk0jqxc9d724n-libunistring-1.4.1' from 'https://install.determinate.systems'...
copying path '/nix/store/1ga782ml07vy0h503ac4cin0h8d7q6yh-libidn2-2.3.8' from 'https://install.determinate.systems'...
copying path '/nix/store/jms7zxzm7w1whczwny5m3gkgdjghmi2r-glibc-2.42-51' from 'https://install.determinate.systems'...
copying path '/nix/store/10s5j3mfdg22k1597x580qrhprnzcjwb-hello-2.12.3' from 'https://cache.nixos.org'...
Hello, world!
```

### 1.2 Application Code

`labs/lab11/app/main.go`:

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

`labs/lab11/app/go.mod`:

```go
module example.com/nix-repro-app

go 1.22
```

### 1.3 Nix Derivation

`labs/lab11/app/default.nix`:

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      type == "directory"
      || builtins.elem (baseNameOf path) [
        "go.mod"
        "main.go"
      ];
  };
  vendorHash = null;

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-buildid="
  ];

  postInstall = ''
    mv "$out/bin/nix-repro-app" "$out/bin/app"
  '';
}
```

Explanation:

- `buildGoModule` builds the Go application in an isolated Nix build environment.
- `src` is filtered to include only `main.go` and `go.mod`, preventing generated files like Docker build artifacts from changing the Nix input hash.
- `vendorHash = null` is valid because this application has no third-party Go module dependencies.
- `CGO_ENABLED = 0` makes the binary static, which is useful for minimal Docker images.
- `-buildid=` removes the Go build ID, avoiding an unnecessary source of build variation.
- `postInstall` renames the generated binary to `app`, matching the lab instructions.

### 1.4 Reproducibility Proof

Command:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && rm -f result app-binary && nix-build && readlink result && sha256sum ./result/bin/app && rm -f result && nix-build && readlink result && sha256sum ./result/bin/app
```

Output:

```text
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
this derivation will be built:
  /nix/store/s4342g621xpdvrfxi5idhj6liy6psxxd-app-1.0.0.drv
building '/nix/store/s4342g621xpdvrfxi5idhj6liy6psxxd-app-1.0.0.drv'...
Running phase: unpackPhase
unpacking source archive /nix/store/6lhxmf8mppdmdb7zb1nlwrvng710g15w-source
source root is source
Running phase: patchPhase
Running phase: updateAutotoolsGnuConfigScriptsPhase
Running phase: configurePhase
Running phase: buildPhase
Building subPackage .
Running phase: checkPhase
Running phase: installPhase
Running phase: fixupPhase
shrinking RPATHs of ELF executables and libraries in /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
shrinking /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0/bin/app
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
checking for references to /build/ in /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0...
patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
patching script interpreter paths in /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
stripping (with command strip and flags -S -p) in  /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0/bin
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
63274c5b534705cb3e242d54377766a56a860d30dad8c12a026a28ce3adfefb3  ./result/bin/app
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
63274c5b534705cb3e242d54377766a56a860d30dad8c12a026a28ce3adfefb3  ./result/bin/app
```

Result:

```text
Build 1 store path: /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
Build 2 store path: /nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
Binary SHA256: 63274c5b534705cb3e242d54377766a56a860d30dad8c12a026a28ce3adfefb3
```

The store path and binary hash are identical across repeated builds.

### 1.5 Docker Comparison

Traditional Dockerfile:

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
CMD ["./app"]
```

Command:

```bash
docker build --no-cache -t test-app:first .
docker image inspect test-app:first --format '{{.Id}} {{.Created}}'
sleep 2
docker build --no-cache -t test-app:second .
docker image inspect test-app:second --format '{{.Id}} {{.Created}}'
```

Output summary:

```text
sha256:fc2e77f12a48f4e6e920bc992664aa73923255ac79859c6483b5c059eaac1871 2026-04-15T16:20:16.181208225+03:00
sha256:0936fdc890771ac71c05d3e40657da98b496804d4666ee5c147e25a3ddc1b190 2026-04-15T16:20:25.821659878+03:00
```

The two Docker builds produced different image IDs and different creation timestamps. Docker can be made more reproducible with extra discipline, but a normal Dockerfile still depends on mutable tags, timestamps, build context behavior, and the builder environment.

### 1.6 Analysis

Nix builds are reproducible because every build is expressed as a derivation with declared inputs. The build runs in an isolated environment and only sees the dependencies Nix provides. The output path is derived from the inputs, so when the inputs do not change, the output path and binary hash remain identical.

Nix store path format:

```text
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
```

- `/nix/store` is the global Nix content-addressed store.
- `01y21dpmhfkwy8m2957jfbrn64xhib75` is the hash-like prefix derived from the derivation inputs.
- `app` is the package name.
- `1.0.0` is the package version.

## Task 2 — Reproducible Docker Images with Nix

### 2.1 Docker Image with Nix

`labs/lab11/app/docker.nix`:

```nix
{ pkgs ? import <nixpkgs> { } }:

let
  app = pkgs.callPackage ./default.nix { };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-repro-app";
  tag = "latest";

  contents = [ app ];
  created = "1970-01-01T00:00:01Z";

  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
```

Explanation:

- `dockerTools.buildLayeredImage` creates a Docker image tarball from Nix store paths.
- `contents = [ app ]` includes the app derivation and its closure.
- `created` is fixed to a constant timestamp so image metadata does not change between builds.
- `config.Cmd` points directly to the reproducible Nix-built binary.

### 2.2 Nix Docker Image Build and Reproducibility

Command:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && rm -f result && nix-build docker.nix && readlink result && sha256sum result && rm -f result && nix-build docker.nix && readlink result && sha256sum result && docker load < result && docker run --rm nix-repro-app
```

Output:

```text
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
these 7 derivations will be built:
  /nix/store/1xbx1lmqp1cgl2biflc8w5adkavy4yyr-nix-repro-app-base.json.drv
  /nix/store/l33xlcb2c12iwyxhwh997wri62mm89xj-nix-repro-app-customisation-layer.drv
  /nix/store/ba0yimyzgwdnflshn030dw71pnc2wa5g-excludePaths.drv
  /nix/store/nvwwfcf4qjaf19qm50nincx9sr5s0j2b-layers.json.drv
  /nix/store/8w6iz96ljxzxxk2vr8zdad50y8kpj6ks-nix-repro-app-conf.json.drv
  /nix/store/40f6izl7jm98g5i52lgp341cgxfp4dg9-stream-nix-repro-app.drv
  /nix/store/xqwdipvn3r1gip0iph6k08w2vr1g6354-nix-repro-app.tar.gz.drv
building '/nix/store/1xbx1lmqp1cgl2biflc8w5adkavy4yyr-nix-repro-app-base.json.drv'...
building '/nix/store/l33xlcb2c12iwyxhwh997wri62mm89xj-nix-repro-app-customisation-layer.drv'...
building '/nix/store/ba0yimyzgwdnflshn030dw71pnc2wa5g-excludePaths.drv'...
building '/nix/store/nvwwfcf4qjaf19qm50nincx9sr5s0j2b-layers.json.drv'...
structuredAttrs is enabled
building '/nix/store/8w6iz96ljxzxxk2vr8zdad50y8kpj6ks-nix-repro-app-conf.json.drv'...
{
  "architecture": "amd64",
  "config": {
    "Cmd": [
      "/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0/bin/app"
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
      "/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0"
    ]
  ],
  "customisation_layer": "/nix/store/3z6grf5g1m18nl6rxi6mnmfgw8hsjjqn-nix-repro-app-customisation-layer",
  "repo_tag": "nix-repro-app:latest",
  "created": "1970-01-01T00:00:01+00:00",
  "mtime": "1970-01-01T00:00:01+00:00",
  "uid": "0",
  "gid": "0",
  "uname": "root",
  "gname": "root"
}
building '/nix/store/40f6izl7jm98g5i52lgp341cgxfp4dg9-stream-nix-repro-app.drv'...
building '/nix/store/xqwdipvn3r1gip0iph6k08w2vr1g6354-nix-repro-app.tar.gz.drv'...
No 'fromImage' provided
Creating layer 1 from paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
Creating layer 2 from paths: ['/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0']
Creating layer 3 with customisation...
Adding manifests...
Done.
/nix/store/wbriqf65s9y283scj0q0167k8s15s9ny-nix-repro-app.tar.gz
/nix/store/wbriqf65s9y283scj0q0167k8s15s9ny-nix-repro-app.tar.gz
248552e301dd726043af273a7f83564067e53fd73a7a03fadc718113148362de  result
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
/nix/store/wbriqf65s9y283scj0q0167k8s15s9ny-nix-repro-app.tar.gz
/nix/store/wbriqf65s9y283scj0q0167k8s15s9ny-nix-repro-app.tar.gz
248552e301dd726043af273a7f83564067e53fd73a7a03fadc718113148362de  result
Loaded image: nix-repro-app:latest
Built with Nix at compile time
Running at: 2026-04-15T13:17:08Z
```

Result:

```text
Docker tarball store path: /nix/store/wbriqf65s9y283scj0q0167k8s15s9ny-nix-repro-app.tar.gz
Docker tarball SHA256: 248552e301dd726043af273a7f83564067e53fd73a7a03fadc718113148362de
```

The Nix-built image tarball reproduced exactly across repeated builds.

### 2.3 Traditional Dockerfile Comparison

`labs/lab11/app/Dockerfile.traditional`:

```dockerfile
FROM scratch
COPY app-binary /app
ENTRYPOINT ["/app"]
```

Command:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && rm -f result app-binary && nix-build && cp result/bin/app app-binary && docker build -f Dockerfile.traditional -t traditional-app . && docker images | grep -E 'nix-repro-app|traditional-app|REPOSITORY' && docker history nix-repro-app && docker history traditional-app
```

Output:

```text
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile.traditional
#1 transferring dockerfile: 103B done
#1 DONE 0.0s

#2 [internal] load .dockerignore
#2 transferring context: 2B done
#2 DONE 0.0s

#3 [internal] load build context
#3 transferring context: 1.66MB 0.1s done
#3 DONE 0.1s

#4 [1/1] COPY app-binary /app
#4 CACHED

#5 exporting to image
#5 exporting layers done
#5 writing image sha256:55f9fc630daf7065e9e278fbf1ffef391764a9b1ab3d6e2be2d38f4ae415c04a done
#5 naming to docker.io/library/traditional-app done
#5 DONE 0.0s
WARNING: This output is designed for human readability. For machine-readable output, please use --format.
nix-repro-app:latest     fe6f5c73294e       3.56MB             0B
traditional-app:latest   55f9fc630daf       1.65MB             0B
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
fe6f5c73294e   N/A                    61B       store paths: ['/nix/store/3z6grf5g1m18nl6rxi6mnmfgw8hsjjqn-nix-repro-app-customisation-layer']
<missing>      N/A                    1.65MB    store paths: ['/nix/store/01y21dpmhfkwy8m2957jfbrn64xhib75-app-1.0.0']
<missing>      N/A                    1.9MB     store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
IMAGE          CREATED              CREATED BY                        SIZE      COMMENT
55f9fc630daf   About a minute ago   ENTRYPOINT ["/app"]               0B        buildkit.dockerfile.v0
<missing>      About a minute ago   COPY app-binary /app # buildkit   1.65MB    buildkit.dockerfile.v0
```

Image size comparison:

| Image | Size |
| --- | ---: |
| Nix `dockerTools` image | 3.56 MB |
| Traditional `scratch` image | 1.65 MB |

The traditional image is smaller in this particular example because it is manually optimized to contain only the static binary. The Nix image is still small, but it includes the app as a Nix store path plus a `tzdata` layer. Compared with a normal `golang:1.22` runtime image, the Nix image is much smaller and avoids the mutable base-image problem.

### 2.4 Layer Structure and Practical Advantages

The Nix image history shows store-path layers and no normal creation timestamp (`N/A`). This is useful because layers correspond to exact Nix store paths, which are derived from declared inputs. The traditional image history shows Dockerfile instructions and relative creation times like `About a minute ago`, which are less useful for reproducibility.

Practical advantages of content-addressable Docker images:

- exact dependency traceability through store paths
- repeatable image tarball hashes
- deterministic timestamps when configured correctly
- smaller closure than full language runtime images
- easier audit and rollback because the image is built from explicit Nix inputs

## Bonus Task — Modern Nix with Flakes

### Bonus.1 Flake Definition

`labs/lab11/app/flake.nix`:

```nix
{
  description = "Lab 11 reproducible Go app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      app = pkgs.callPackage ./default.nix { };
      dockerImage = pkgs.callPackage ./docker.nix { };
    in
    {
      packages.${system}.default = app;
      dockerImages.${system}.default = dockerImage;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.go
          pkgs.gopls
        ];
      };
    };
}
```

### Bonus.2 Lock File

Command:

```bash
nix --extra-experimental-features 'nix-command flakes' flake update
```

`flake.lock` snippet:

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1767313136,
        "narHash": "sha256-16KkgfdYqjaeRGBaYsNrhPRRENs0qzkQVUooNHtoy2w=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "ac62194c3917d5f474c1a844b6fd6da2db95077d",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-25.05",
        "repo": "nixpkgs",
        "type": "github"
      }
    }
  }
}
```

The lock file pins `nixpkgs` to a specific commit and content hash, which makes future builds use the same dependency universe.

### Bonus.3 Flake Build Outputs

Command:

```bash
nix --extra-experimental-features 'nix-command flakes' build
nix --extra-experimental-features 'nix-command flakes' build .#dockerImages.x86_64-linux.default
sha256sum result
```

Output excerpt:

```text
warning: creating lock file "/home/nikkimen/Documents/Studies/IntroDevops/DevOps-Intro/labs/lab11/app/flake.lock":
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/ac62194' (2026-01-02)
warning: Git tree '/home/nikkimen/Documents/Studies/IntroDevops/DevOps-Intro' has uncommitted changes
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
/nix/store/5lg65y3ma945b8pcvzl0a5rn6flinyi0-app-1.0.0
warning: Git tree '/home/nikkimen/Documents/Studies/IntroDevops/DevOps-Intro' has uncommitted changes
evaluation warning: `-buildid=` is set by default as ldflag by buildGoModule
/nix/store/b992jf4dnsydl9gv2rqk9g10v2kib2rn-nix-repro-app.tar.gz
5685156416ed99f9cbfb19ca90ee3c9f45e5a58749e5a2bacc0c985f0d709a1f  result
```

The flake app store path differs from the earlier non-flake build because the flake pins a different `nixpkgs` revision. Within the flake, builds are reproducible because the exact `nixpkgs` revision is locked.

### Bonus.4 Development Shell

Command:

```bash
nix --extra-experimental-features 'nix-command flakes' develop -c go version
nix --extra-experimental-features 'nix-command flakes' develop -c gopls version
```

Output:

```text
copying path '/nix/store/gb3r476ihwl2gbgk7da4isqlnl4qjb41-gopls-0.19.1' from 'https://cache.nixos.org'...
building '/nix/store/l89qqq922vi7bnnh9a1j1l4cy8rmip3g-nix-shell-env.drv'...
these 2 paths will be fetched (0.0 KiB download, 7.0 MiB unpacked):
  /nix/store/nn27l879np49xvx6l1a8nqnqlp9apd8n-bash-interactive-5.2p37
  /nix/store/vqa7av1kxk2g0a8pyca98dv1rcb9n2dg-bash-interactive-5.2p37-man
copying path '/nix/store/vqa7av1kxk2g0a8pyca98dv1rcb9n2dg-bash-interactive-5.2p37-man' from 'https://install.determinate.systems'...
copying path '/nix/store/nn27l879np49xvx6l1a8nqnqlp9apd8n-bash-interactive-5.2p37' from 'https://install.determinate.systems'...
go version go1.24.10 linux/amd64
warning: Git tree '/home/nikkimen/Documents/Studies/IntroDevops/DevOps-Intro' has uncommitted changes
golang.org/x/tools/gopls v0.19.1
```

### Bonus.5 Reflection

Flakes improve traditional Nix expressions by making inputs explicit and locked. A normal `default.nix` using `<nixpkgs>` depends on whatever `NIX_PATH` currently points to, while a flake records the exact dependency revision in `flake.lock`. Flakes also standardize outputs like `packages`, `devShells`, and Docker images, which makes projects easier to build on another machine or in CI.

The dev shell is better than a traditional setup because developers do not need to manually install matching Go and language-server versions. Running `nix develop` provides the same toolchain to every contributor and CI job.
