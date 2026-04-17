{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "lab11-app";
  tag = "latest";
  contents = [ app ];
  config = {
    Cmd = [ "/bin/app" ];
  };
}
