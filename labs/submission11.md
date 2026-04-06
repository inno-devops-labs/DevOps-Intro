# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### Installation steps and verification output
```bash
pixel@pixelbook:~/DevOps-Intro$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
info: downloading the Determinate Nix Installer
 INFO nix-installer v3.17.2
`nix-installer` needs to run as `root`, attempting to escalate now via `sudo`...
[sudo: authenticate] Password: 
 INFO nix-installer v3.17.2
Nix install plan (v3.17.2)
Planner: linux (with default settings)

Planned actions:
* Create directory `/nix`
* Install Determinate Nixd
* Extract the bundled Nix (originally from /nix/store/rszdb7kbxq98k2cngm6fbg3rjidhrcid-nix-binary-tarball-3.17.2/nix-3.17.2-x86_64-linux.tar.xz) to `/nix/temp-install-dir`
* Create a directory tree in `/nix`
* Synchronize /nix and /nix/var ownership
* Move the downloaded Nix into `/nix`
* Synchronize /nix/store ownership
* Create build users (UID 30001-30032) and group (GID 30000)
* Setup the default Nix profile
* Place the Nix configuration in `/etc/nix/nix.conf`
* Configure the shell profiles
* Configure the Determinate Nix daemon
* Cleanup


Proceed? ([Y]es/[n]o/[e]xplain): y
 INFO Step: Create directory `/nix`
 INFO Step: Install Determinate Nixd
 INFO Step: Provision Nix
 INFO Step: Create build users (UID 30001-30032) and group (GID 30000)
 INFO Step: Configure Nix
 INFO Step: Create directory `/etc/tmpfiles.d`
 INFO Step: Configure the Determinate Nix daemon
 INFO Step: Cleanup
 INFO Running self test for shell sh
 INFO Running self test for shell bash
Nix was installed successfully!
To get started using Nix, open a new shell or run `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`


pixel@pixelbook:~/DevOps-Intro$ . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
pixel@pixelbook:~/DevOps-Intro$ nix --version
nix (Determinate Nix 3.17.2) 2.33.3
```


### Your `default.nix` file with explanations
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule rec {
  pname = "hello-go";
  version = "0.1.0";

  src = ./.;

  vendorHash = null;
}
```

Explanation:
- `{ pkgs ? import <nixpkgs> {} }:`: loads the Nix packages collection
- `pkgs.buildGoModule {`: uses the Go builder from Nixpkgs
- `pname = "hello-go";`: sets the package name
- `version = "0.1.0";`: sets the package version
- `src = ./.;`: uses the current directory as the source code
- `vendorHash = null;`: no external Go dependencies, so no vendored modules are needed


### Store path from multiple builds (prove they're identical)
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ readlink result
/nix/store/gw9i48pmm85gvxiw43g5hsdy03jiq475-hello-go-0.1.0

pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ rm result

pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ nix-build
/nix/store/gw9i48pmm85gvxiw43g5hsdy03jiq475-hello-go-0.1.0
```

Identical.


### SHA256 hash of the binary
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ sha256sum ./result/bin/hello-go 
3c216b71f0b0053ab74f081971f328dd048d948855804902825f0745ff36bea4  ./result/bin/hello-go
```


### Comparison with Docker: Why is Docker not reproducible?
Via `docker images --digests`:
- First build: `sha256:51fa29b92c2ac0e10f25c70b34498a5f3a15ef38d80157c9b729fa39345d5196`
- Second build: `sha256:873b07aaa27eb42fe5ce76461106c2934856c1f3d9a2303b609a99dec44a1dfe`
Not identical.

Why? Because docker builds depend on mutable external state: `FROM golang:1.22` - this is a mutable tag. Later, it may point to a newer image with different OS packages, patches, or Go minor versions.


### Analysis: What makes Nix builds reproducible?
Nix builds are reproducible because all inputs are fixed and hashed:
- Exact package versions are pinned in `nixpkgs`
- Dependencies are stored immutably in `/nix/store`
- Builds run in isolated sandboxes
- Output paths include a hash of all build inputs
- Same inputs always produce the same output path and binary


### Explanation of the Nix store path format and what each part means
`/nix/store/gw9i48pmm85gvxiw43g5hsdy03jiq475-hello-go-0.1.0`:
- `/nix/store/` — the directory where Nix stores all built packages
- `gw9i48pmm85gvxiw43g5hsdy03jiq475` — a hash derived from all build inputs
- `hello-go` — the package name (pname)
- `0.1.0` — the package version (version)


## Task 2 — Reproducible Docker Images with Nix

### `docker.nix` file with explanations
```nix
{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "hello-go";
  tag = "0.1.0";

  contents = [ app ];

  config = {
    Cmd = [ "/bin/hello-go" ];
  };
}
```

Explanation:
- `{ pkgs ? import <nixpkgs> {} }:`: loads the Nix package collection
- `let app = import ./default.nix { inherit pkgs; }; in`: imports the Go package from `default.nix` and stores it in `app`
- `pkgs.dockerTools.buildLayeredImage {`: uses Nix's Docker image builder
- `name = "hello-go";`: sets the Docker image name
- `tag = "0.1.0";`: sets the Docker image tag
- `contents = [ app ];`: adds the built Go application into the image
- `config = { Cmd = [ "/bin/hello-go" ]; };`: sets the default command that runs when the container starts. `/bin/hello-go` exists because Nix packages place binaries under `/bin`.


### Image size comparison: Nix vs traditional Dockerfile
Via `docker images`:
- Nix `hello-go:0.1.0`: 11.9MB
- Docker `traditional-app:latest`: 3.26MB

Full output:
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ docker images
                                                                                                                                                       i Info →   U  In Use
IMAGE                            ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:latest                    25109184c71b       13.1MB         3.95MB        
aquasec/trivy:0.69.3             bcc376de8d77        245MB         59.1MB        
bkimminich/juice-shop:latest     5539448a1d3f        753MB          179MB    U   
ghcr.io/zaproxy/zaproxy:stable   c4da4c234258       3.42GB         1.11GB        
hello-go:0.1.0                   903b159ce519       11.9MB         4.75MB    U   
my_website:latest                de0d0d4a4921        237MB         62.9MB        
nginx:latest                     0236ee02dcbc        240MB         65.8MB    U   
test-app:latest                  873b07aaa27e       1.25GB          306MB        
traditional-app:latest           97b15ae830c1       3.26MB         1.24MB        
ubuntu:latest                    d1e2e92c075e        119MB         31.7MB     
```

### SHA256 hashes proving reproducibility
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ rm result
nix-build docker.nix
sha256sum result

rm result
nix-build docker.nix
sha256sum result

/nix/store/mlfg0s4752sr56vpyrg505wgrj3i5145-hello-go.tar.gz
39a6de81c48707c61ad8be4e33f23a2a8041b51c9d26810df35871b09e2ef2c6  result
/nix/store/mlfg0s4752sr56vpyrg505wgrj3i5145-hello-go.tar.gz
39a6de81c48707c61ad8be4e33f23a2a8041b51c9d26810df35871b09e2ef2c6  result
```

Hashes are identical. Builds are reproducible.


### Docker history output for both images
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ docker history traditional-app
IMAGE          CREATED         CREATED BY                      SIZE      COMMENT
97b15ae830c1   2 minutes ago   ENTRYPOINT ["/app"]             0B        buildkit.dockerfile.v0
<missing>      2 minutes ago   COPY /src/app /app # buildkit   2.02MB    buildkit.dockerfile.v0
```

```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ docker history  hello-go:0.1.0
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
903b159ce519   N/A                    12.3kB    store paths: ['/nix/store/m2fh9lfwjpdm3j3fapivr0h07d03qqvy-hello-go-customisation-layer']
<missing>      N/A                    1.81MB    store paths: ['/nix/store/r9xjhswak0asj29ib2d9pnygls5qzzjk-hello-go-0.1.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
```


### Analysis: Why are Nix-built images smaller and more reproducible?
Nix-built images are usually more reproducible because all build inputs are explicitly defined and stored immutably in the Nix store. However, they are not always smaller. In this example, the Nix image is larger than the traditional Docker image because it includes the application together with its Nix store closure and additional runtime data such as tzdata. The traditional image is smaller because it copies only a single compiled binary into a minimal scratch image.


### Layer structure comparison
The traditional Docker image has a very simple layer structure:
- One layer for the compiled binary
- One metadata layer for the entrypoint

The Nix-built image has multiple layers:
- One layer for the Go application
- One layer for tzdata
- One layer for image customisation metadata

This happens because buildLayeredImage creates separate layers for different Nix store paths. That makes layers more reusable across images, even if the total image is larger.


### Practical advantages of content-addressable Docker images
- Images are immutable: the SHA256 digest always refers to exactly one image
- Builds become more reproducible because the exact image can be pinned with a digest instead of a mutable tag like `latest`
- Easier verification: you can compare hashes to confirm two images are identical
- Better caching: unchanged layers can be reused safely
- More secure deployments: production can use exact image digests and avoid accidental upgrades
- Easier rollback: an old digest always points to the same previous image version


## Bonus Task — Modern Nix with Flakes

### Complete `flake.nix` with explanations
```nix
{
  description = "My test app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      app = pkgs.buildGoModule {
        pname = "hello-go";
        version = "0.1.0";
        src = ./.;
        vendorHash = null;
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "hello-go";
        tag = "0.1.0";
        contents = [ app ];
        config = {
          Cmd = [ "/bin/hello-go" ];
        };
      };
    in {
      packages.${system}.default = app;
      dockerImages.${system}.default = dockerImage;
    };
}
```

Explanation:
- `description = "My test app";`: a short description of the flake
- `inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";};`: pins the exact Nixpkgs version so builds are reproducible
- `outputs = { self, nixpkgs }:`: defines what the flake produces
- `let system = "x86_64-linux"; pkgs = import nixpkgs { inherit system; };`: selects the target platform and loads the package set for that platform
- `app = pkgs.buildGoModule { pname = "hello-go"; version = "0.1.0"; src = ./.; vendorHash = null;};`: builds the Go application from the current directory
- `dockerImage = pkgs.dockerTools.buildLayeredImage { name = "hello-go"; tag = "0.1.0"; contents = [ app ];`: builds a Docker image containing the Go app
- `config = {Cmd = [ "/bin/hello-go" ];};`: sets the command that runs when the container starts
- `packages.${system}.default = app;`: makes the Go app the default package output
- `dockerImages.${system}.default = dockerImage;`: makes the Docker image available as the default Docker image output


### `flake.lock` snippet showing locked dependencies
```lock
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1720535198,
        "narHash": "sha256-zwVvxrdIzralnSbcpghA92tWu2DV2lwv89xZc8MTrbg=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "205fd4226592cc83fd4c0885a3e4c9c400efabb5",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-23.11",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```


### Build outputs from `nix build`
Nothing, because it builds correctly.


### Proof that builds are identical across machines/time
On host machine(Ubuntu):
```bash
pixel@pixelbook:~/DevOps-Intro/labs/lab11/app$ readlink result
/nix/store/p6nh1rw3kdzgyi5k6s9bkih2f9lk1cc9-hello-go-0.1.0
```

On another machine(Debian):
```bash
pixel@pixelbook:~$ readlink result
/nix/store/p6nh1rw3kdzgyi5k6s9bkih2f9lk1cc9-hello-go-0.1.0
```


### Dev shell experience: Why is this better than traditional dev setups?
- Everyone gets the same versions of tools and dependencies
- No manual installation steps are needed on each machine
- New developers can start quickly with one command like `nix develop`
- Works consistently across different Linux machines
- Avoids “works on my machine” problems
- Different projects can use different tool versions without conflicts
- The environment is reproducible because it is defined in code rather than set up manually


### Reflection: How do Flakes improve upon traditional Nix expressions?
- Flakes pin dependencies explicitly through `inputs`
- They provide reproducible builds across machines
- Outputs are standardized (`packages`, `devShells`, `checks`, etc.)
- They make it easier to share and reuse projects directly from Git repositories
- Lock files ensure everyone uses the same dependency versions
- Commands are simpler, such as `nix build`, `nix run`, and `nix develop`
- They reduce ambiguity compared with older `default.nix` and channel-based setups