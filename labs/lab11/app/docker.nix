{ pkgs ? import <nixpkgs> {} }:

let
  linuxTarget =
    if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64-unknown-linux-gnu"
    else if pkgs.stdenv.hostPlatform.isx86_64 then "x86_64-unknown-linux-gnu"
    else throw "docker.nix: add a linux crossSystem for this host";

  # Cross pkgs: Go binary is linux/{arm64|amd64}, matching typical Docker on Mac.
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
