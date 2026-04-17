{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "hello";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;
}
