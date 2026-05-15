let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
  app = pkgs.buildGoModule {
    pname = "app";
    version = "1.0.0";
    src = pkgs.lib.cleanSource ./.;
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
