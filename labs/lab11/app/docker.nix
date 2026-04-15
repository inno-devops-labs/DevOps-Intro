let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
  app = import ./default.nix;
in
pkgs.dockerTools.buildImage {
  name = "lab11-app";
  tag = "latest";
  copyToRoot = [ app ];
  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}