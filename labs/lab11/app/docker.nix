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