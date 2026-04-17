{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0";

  src = ./.;

  vendorHash = null;
}
