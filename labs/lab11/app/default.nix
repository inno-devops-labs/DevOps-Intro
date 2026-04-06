{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule rec {
  pname = "hello-go";
  version = "0.1.0";

  src = ./.;

  vendorHash = null;
}