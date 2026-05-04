# Solution

## Task 1

Installation proof:

```bash
(hw) lexandrinnn_t@63906:~/inno/devops/DevOps-Intro$ nix --version
nix (Determinate Nix 3.19.0) 2.34.6
(hw) lexandrinnn_t@63906:~/inno/devops/DevOps-Intro$ nix run nixpkgs#hello
Hello, world!
```

Explained `default.nix`:

```nix
# the file is a function whose default argument is “the Nixpkgs set” (all standard packages and builders).
{ pkgs ? import <nixpkgs> { } }:

# Use Nix’s Go-module builder
pkgs.buildGoModule rec {
  pname = "lab11-app";
  version = "0.1.0";

  src = ./.;  # Build from this directory

  vendorHash = null; # No third-party Go modules are vendored

  ldflags = [ "-s" "-w" ]; # Pass linker flags to Go: strip symbol table / debug info and DWARF debug info

  # Metadata Nix tools can show
  meta = with pkgs.lib; {
    description = "Lab 11 Go sample (stdlib only)";
    license = licenses.mit;
    mainProgram = pname;
  };
}

```

Paths (different):
```bash
(hw) lexandrinnn_t@63906:~/inno/devops/DevOps-Intro/labs/lab11/app$ readlink result
/nix/store/rkw3l70g3kn4sigsq2rk9k2wk5w361yn-lab11-app-0.1.0
(hw) lexandrinnn_t@63906:~/inno/devops/DevOps-Intro/labs/lab11/app$ rm result
nix-build
readlink result
...
/nix/store/rkw3l70g3kn4sigsq2rk9k2wk5w361yn-lab11-app-0.1.0
```

Hash of the binary: `b92df2b454189f31dd5263b4ca784078564e3365af725ab95a9d3ab3d4c433cd`  

**Docker** is not reproducible due to base image moves, cache/provenance metadata changes, and built artifacts can differ unlike a **fixed-input Nix derivation** where the store path is fully determined by hashed inputs.  

**Nix store path:** `/nix/store/<store-path-hash>-<pname-version>`

## Task 2

Explained `docker.nix`:
```nix
# The file is a Nix function. The argument pkgs defaults to your nixpkgs package set (all builders and packages).
{ pkgs ? import <nixpkgs> { } }:

# Build the same Go app as in Task 1
let
  lab11-app = import ./default.nix { inherit pkgs; };
in

# Uses Nix dockerTools to build an OCI Docker image without a Dockerfile
pkgs.dockerTools.buildLayeredImage {
  # Sets the image reference
  name = "lab11-app";
  tag = "latest";

  # Lists which Nix packages are copied into the image
  contents = [
    lab11-app
  ];

  config = {
    # Exact store path to the Go binary from the Task 1 derivation (reproducible).
    Cmd = [
      (pkgs.lib.getExe lab11-app)
    ];
  };
}
```

Sizes comparison:

```bash
lab11-app:latest                                        34fc1efab212       11.6MB         4.61MB        
traditional-app:latest                                  669e14e8bc4d       2.41MB          756kB   
```
Docker history for Nix-built image:
```bash
(hw) lexandrinnn_t@63906:~/inno/devops/DevOps-Intro/labs/lab11/app$ docker history lab11-app:latest
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
34fc1efab212   N/A                    12.3kB    store paths: ['/nix/store/jmssxczi7vzsj0b9rzfr3h0yzqj94l9a-lab11-app-customisation-layer']
<missing>      N/A                    1.68MB    store paths: ['/nix/store/ibjwr62mimglzrk55z3qbqfzai1hxfin-lab11-app-0.1.0']
<missing>      N/A                    5.33MB    store paths: ['/nix/store/cxjmhdbpy3bk12jc6lwpmcvlas76a7zm-tzdata-2026a']
```

Docker history for traditional-app:
```bash
IMAGE          CREATED         CREATED BY                              SIZE      COMMENT
669e14e8bc4d   4 minutes ago   ENTRYPOINT ["/app"]                     0B        buildkit.dockerfile.v0
<missing>      4 minutes ago   COPY lab11-app-binary /app # buildkit   1.66MB    buildkit.dockerfile.v0
```

So in this lab, the scratch + copied static binary image is smaller, not the Nix one. The history explains why.  

**Layer structure**
- Nix: tzdata (~5.33 MB in history) → app (~1.68 MB) → customisation (image config/metadata, ~12 kB).
- Traditional: Single COPY of lab11-app-binary (~1.66 MB), ENTRYPOINT, plus BuildKit’s zero-size instruction rows.  

Nix-built images are more reproducible mainly because:
- Inputs are fixed 
- Stable metadata
- Layers = content-addressed paths, so layers correspond to immutable, named-by-hash artifacts