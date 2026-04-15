{ pkgs ? import <nixpkgs> {} }:
let
  myApp = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-test-app";
  tag = "latest";
  contents = [ myApp ];
  config = {
    Cmd = [ "${myApp}/bin/app" ];
  };
}
