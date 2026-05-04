{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule rec {
  pname = "app";
  version = "0.1.0";

  src = ./.;

  vendorHash = null; 

  doCheck = false;
}