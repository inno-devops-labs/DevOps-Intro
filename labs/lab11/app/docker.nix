{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-lab-app";
  tag = "latest";
  contents = [ app ];

  config = {
    Cmd = [ "${app}/bin/nix-lab-app" ];
  };
}
