{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.callPackage ./default.nix {};
  rootfs = pkgs.buildEnv {
    name = "app-rootfs";
    paths = [ app ];
    pathsToLink = [ "/bin" ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "1.0.0";

  contents = [ rootfs ];

  config = {
    Cmd = [ "/bin/app" ];
  };
}
