{ pkgs ? import <nixpkgs> { } }:

let
  app = pkgs.callPackage ./default.nix { };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-repro-app";
  tag = "latest";

  contents = [ app ];
  created = "1970-01-01T00:00:01Z";

  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
