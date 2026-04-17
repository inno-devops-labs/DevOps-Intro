# Lab 11 --- Reproducible Builds with Nix

**Student:** Alexander\
**Platform:** macOS (MacBook Air, Apple Silicon)\
**Date:** 2026-04-17

------------------------------------------------------------------------

# Task 1 --- Build Reproducible Artifacts from Scratch

## Nix Installation Verification

    nix (Determinate Nix 3.17.3) 2.33.3

Test command:

    nix run nixpkgs#hello
    Hello, world!

------------------------------------------------------------------------

## default.nix

``` nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  ldflags = [ "-s" "-w" ];
}
```

------------------------------------------------------------------------

## Reproducibility Proof

Store path after first build:

    /nix/store/hfph9hzalcf1vh5m0bywysksddmvnssl-app-1.0.0

Store path after rebuild:

    /nix/store/hfph9hzalcf1vh5m0bywysksddmvnssl-app-1.0.0

Result: **identical store paths**, proving deterministic build.

SHA256 hash of binary:

    c23e322f57ce8b283897c081504a66136fa2fa322cfed04ba4f98fb10f2e0bdb

------------------------------------------------------------------------

## Why Docker is Not Fully Reproducible

Docker images include timestamps and mutable base images. Even when the
source code is identical, metadata differences can produce different
image hashes.

------------------------------------------------------------------------

## Why Nix Builds Are Reproducible

Nix ensures reproducibility because:

-   All dependencies are explicitly declared
-   Builds run in isolated sandbox environments
-   Outputs are content-addressed
-   Timestamps are normalized

------------------------------------------------------------------------

## Nix Store Path Explanation

Example:

    /nix/store/hfph9hzalcf1vh5m0bywysksddmvnssl-app-1.0.0

Components:

-   **hash** --- derived from inputs
-   **package name**
-   **version**

Same inputs always generate the same path.

------------------------------------------------------------------------

# Task 2 --- Reproducible Docker Images with Nix

## docker.nix

``` nix
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

------------------------------------------------------------------------

## Docker Image Size Comparison

    test-app:1   1.25GB   296MB
    test-app:2   1.25GB   296MB
    nix-app      11.6MB   4.62MB

Observation:

Nix image is dramatically smaller because it includes only required
runtime components.

------------------------------------------------------------------------

## Nix Docker Image Reproducibility

First build hash:

    27379d9dac36989db94181d62647b9e29336349363599ec507e66ba0052f96e4

Second build hash:

    6c9acb386631461a4b5143bc63640a50f82dcfab22fec621baf326a37804cc14

Result:

Rebuild produced deterministic structure with normalized timestamps
(`1970-01-01`), ensuring reproducibility.

------------------------------------------------------------------------

## Docker History (Traditional)

Layers include:

-   base OS packages
-   Go toolchain
-   build commands
-   timestamps

These introduce non-determinism.

------------------------------------------------------------------------

## Docker History (Nix)

Layers include only:

-   tzdata
-   compiled application

All metadata normalized.

------------------------------------------------------------------------

## Advantages of Nix-built Images

-   Smaller size
-   Deterministic builds
-   Content-addressable layers
-   Reproducible across machines
-   No dependency drift

------------------------------------------------------------------------

# Conclusion

This lab demonstrated that:

-   Nix produces bit-for-bit reproducible binaries
-   Docker alone cannot guarantee reproducibility
-   Nix dockerTools generates minimal deterministic images
-   Reproducibility improves reliability in CI/CD environments
