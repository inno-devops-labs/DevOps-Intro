{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
    pname = "lab11-app";
    version = "1.0.0";

    src = ./.;

    vendorHash = null;
}