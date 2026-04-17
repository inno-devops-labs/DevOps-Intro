{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "lab11-nix-app";
  tag = "v1";

  contents = [
    app
    pkgs.cacert
  ];

  config = {
    Entrypoint = [ "${app}/bin/app" ];
    Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  };
}
