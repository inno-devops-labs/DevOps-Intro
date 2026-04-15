{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null; # У нас нет внешних зависимостей, поэтому null
}
