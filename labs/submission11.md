# Task 1

## Installation steps and verification output

`curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`

Output:

```
info: downloading the Determinate Nix Installer
 INFO nix-installer v3.17.3
`nix-installer` needs to run as `root`, attempting to escalate now via `sudo`...
 INFO nix-installer v3.17.3
Nix install plan (v3.17.3)
Planner: linux (with default settings)

Planned actions:
* Create directory `/nix`
* Install Determinate Nixd
* Extract the bundled Nix (originally from /nix/store/0v93r8bjmdmnyrgirq34al25f98y2dhy-nix-binary-tarball-3.17.3/nix-3.17.3-x86_64-linux.tar.xz) to `/nix/temp-install-dir`
* Create a directory tree in `/nix`
* Synchronize /nix and /nix/var ownership
* Move the downloaded Nix into `/nix`
* Synchronize /nix/store ownership
* Create build users (UID 30001-30032) and group (GID 30000)
* Setup the default Nix profile
* Place the Nix configuration in `/etc/nix/nix.conf`
* Configure the shell profiles
* Install an SELinux Policy for Nix
* Create directory `/etc/tmpfiles.d`
* Configure the Determinate Nix daemon
* Cleanup


Proceed? ([Y]es/[n]o/[e]xplain): y
 INFO Step: Create directory `/nix`
 INFO Step: Install Determinate Nixd
 INFO Step: Provision Nix
 INFO Step: Create build users (UID 30001-30032) and group (GID 30000)
 INFO Step: Configure Nix
 INFO Step: Install an SELinux Policy for Nix
 INFO Step: Create directory `/etc/tmpfiles.d`
 INFO Step: Configure the Determinate Nix daemon
 INFO Step: Cleanup
 INFO Running self test for shell sh
 INFO Running self test for shell bash
Nix was installed successfully!
To get started using Nix, open a new shell or run `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
```

Verification `nix --version`: `nix (Determinate Nix 3.17.3) 2.33.3`

Hello word
```
nix run nixpkgs#hello

Hello, world!
```


## Your default.nix file with explanations


File
```
{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
	pname = "lab11-go-app";
	version = "1.0.0";

	src = ./.;
	nativeBuildInputs = [ pkgs.go ];

	buildPhase = ''
		export GOPATH="$TMPDIR/go"
		export GO111MODULE=off
		export CGO_ENABLED=0
		go build -trimpath -ldflags="-s -w" -o lab11-app main.go
	'';

	installPhase = ''
		mkdir -p $out/bin
		cp lab11-app $out/bin/
	'';
}
```

Explanations:

- `pkgs ? import <nixpkgs> {}`: imports Nix packages and lets Nix choose a default set.
- `stdenv.mkDerivation`: defines the build recipe, inputs, and install steps.
- `src = ./.`: uses the current folder with `main.go` as the build source.
- `nativeBuildInputs = [ pkgs.go ]`: makes the Go compiler available during the build.
- `buildPhase`: compiles the program into a local binary.
- `installPhase`: copies the binary into `$out/bin`, which becomes the immutable Nix result.

## Store path from multiple builds (prove they're identical)

Store path 1: `/nix/store/byy9w1zaqs21dn5h142msjv2kf2ym4zv-lab11-go-app-1.0.0`

Store path 2: `/nix/store/byy9w1zaqs21dn5h142msjv2kf2ym4zv-lab11-go-app-1.0.0`

Seems identical

## SHA256 hash of the binary

`7945e518cad2fade0add7ab5ca2c51f8d424e5ae91f766fe848c6c4568152c06`

Both build have identical hash

## Comparison with Docker: Why is Docker not reproducible?

First docker build hash: `sha256:c753c3630a33084e6fa50988dfa06cd99e7db23e99605fb30da229871437cef5`

Second docker build hash: `sha256:c753c3630a33084e6fa50988dfa06cd99e7db23e99605fb30da229871437cef5`

I have got bit reproducible results since docker images' hashes are identical, i have tried to remove image, but result is the same. But more complicated images with more dependencies can be not reproducible. This may happen due to newer package versions, newer image tags and also build steps on different host machines.

## Analysis: What makes Nix builds reproducible?

Nix builds are reproducible because they are based on derivations that fully describe inputs and build steps. Each dependency is pinned in the Nix store, and builds run in an isolated sandbox, so hidden host state does not affect results. The output path in `/nix/store` is derived from all inputs, meaning the same inputs produce the same store path and binary hash. If any input changes, Nix creates a different output path instead of silently reusing old artifacts

## Explanation of the Nix store path format and what each part mean

For my path: `/nix/store/byy9w1zaqs21dn5h142msjv2kf2ym4zv-lab11-go-app-1.0.0`

- `/nix/store` — the global Nix storage directory.
- `byy9w1zaqs21dn5h142msjv2kf2ym4zv` — a hash of all build inputs (sources, dependencies, build recipe, flags).
- `lab11-go-app-1.0.0` — the human-readable package name and version.


# Task 2 

## docker.nix file with explanations

File

```

{ pkgs ? import <nixpkgs> {} }:

let
	goApp = pkgs.callPackage ./default.nix {};
in
pkgs.dockerTools.buildLayeredImage {
	name = "lab11-go-app";
	tag = "1.0.0";

	contents = [ goApp ];

	config = {
		Cmd = [ "${goApp}/bin/lab11-app" ];
	};
}

```

Explanations

- `pkgs.dockerTools.buildLayeredImage`: builds a layered Docker image from Nix inputs.
- `name` and `tag`: define the image name and version without using mutable timestamps.
- `contents = [ goApp ]`: includes the built Go package in the image.
- `config.Cmd`: sets the default command to run the binary from the Nix store.


## Image size comparison: Nix vs traditional Dockerfile

Nix docker image size: `3.56MB`

Traditional dockerfile image size: `1.31MB`

## SHA256 hashes proving reproducibility

First build: `d86270bbf04d74d1a2a656edbdcdff6d74c695f56b0e8549a5a27b766a141cc3`
Second build: `d86270bbf04d74d1a2a656edbdcdff6d74c695f56b0e8549a5a27b766a141cc3`

Identical hashes, so reproducibility is proved

## Docker history output for both images

Nix image history:
```
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
d65f9d40546a   N/A                    76B       store paths: ['/nix/store/bvvw28947lv3j0pwch3dfrbzanmlfdkb-lab11-go-app-customisation-layer']
<missing>      N/A                    1.66MB    store paths: ['/nix/store/fff77z0fz6lw6x4zbjpy4kg2gvim3az6-lab11-go-app-1.0.0']
<missing>      N/A                    1.9MB     store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
```

Traditional docker history:

```
IMAGE          CREATED         CREATED BY                            SIZE      COMMENT
aeff2de278b7   4 minutes ago   ENTRYPOINT ["/app"]                   0B        buildkit.dockerfile.v0
<missing>      4 minutes ago   COPY /out/lab11-app /app # buildkit   1.31MB    buildkit.dockerfile.v0
```


## Analysis: Why are Nix-built images smaller and more reproducible?

Nix builds images from exact derivations, so every input is explicit and immutable. That makes the result easier to cache, reproduce, and compare across machines. But in my experiments I have got docker images smaller then nix built. I think this happens due to simplicity of dependencies and code, in more complex images that won't be true

## Layer structure comparison

`buildLayeredImage` creates a cleaner layer layout by separating the runtime closure into deterministic layers instead of mixing build steps with runtime content. So we have 3 layers in nix built image. 

A traditional Dockerfile image usually has fewer layers here, because it only includes the builder output and the final `COPY` step.  
In my case, the traditional image has 2 layers: the `COPY` layer and the final `ENTRYPOINT` metadata layer.


## Practical advantages of content-addressable Docker images

Content-addressed images are easier to verify, cache, and distribute because identical inputs map to identical outputs. That reduces rebuild noise and makes debugging version drift simpler.
