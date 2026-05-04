{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.buildGoModule {
    pname = "app";
    version = "0.1.0";
    src = ./.;
    vendorHash = null;
    doCheck = false;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";
  contents = [ app ];
  config = {
    Entrypoint = [ "${app}/bin/app" ];
  };
}