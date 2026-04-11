{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.buildGoModule {
    pname = "lab11-app";
    version = "0.1.0";
    src = ./.;
    vendorHash = null;
  };
in

pkgs.dockerTools.buildLayeredImage {
  name = "lab11-app";
  tag = "latest";
  
  contents = [ app ];
  
  config = {
    Cmd = [ "${app}/bin/lab11-app" ];
    WorkingDir = "/app";
  };
}
