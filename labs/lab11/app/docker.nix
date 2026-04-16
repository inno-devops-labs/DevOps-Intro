{ pkgs ? import <nixpkgs> {} }:
let app = import ./default.nix { inherit pkgs; };
in pkgs.dockerTools.buildLayeredImage {
  name = "nix-go-app-image";
  tag = "latest";
  contents = [ app ];
  config = { Cmd = [ "${app}/bin/myapp" ]; };
}
