{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.callPackage ./default.nix {};
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
  };
}
