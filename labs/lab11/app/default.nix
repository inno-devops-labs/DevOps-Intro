let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
in
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = pkgs.lib.cleanSource ./.;
  vendorHash = null;
}
