{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildImage {
  name = "nix-repro-app";
  tag = "latest";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ app ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Cmd = [ "/bin/reproducible-go-app" ];
  };
}
