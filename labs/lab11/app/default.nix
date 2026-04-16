{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
  pname = "testApp";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}
