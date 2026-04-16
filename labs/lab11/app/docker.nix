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
