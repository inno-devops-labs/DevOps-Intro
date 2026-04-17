{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.buildGoModule {
    pname = "app";
    version = "1.0";
    src = ./.;
    vendorHash = null;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  contents = [ app ];

  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
