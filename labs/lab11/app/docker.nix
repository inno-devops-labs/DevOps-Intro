{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:

let
  app = pkgs.buildGoModule {
    pname = "testApp";
    version = "1.0.0";
    src = ./.;
    vendorHash = null;
  };
in
pkgs.dockerTools.buildImage {
  name = "nix-test-app";
  tag = "latest";
  
  config = {
    Cmd = [ "${app}/bin/my-app" ];
  };
}
