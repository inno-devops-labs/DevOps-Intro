{ pkgs ? import <nixpkgs> {} }:

let
  appBin = pkgs.runCommand "app-bin" { buildInputs = [ pkgs.go ]; } ''
    mkdir -p $out/bin
    cp ${./main.go} main.go
    go build -ldflags="-s -w" -o app main.go
    cp app $out/bin/
  '';
in
  pkgs.dockerTools.buildLayeredImage {
    name = "nix-reproducible-app";
    tag = "latest";
    contents = [ appBin ];
    config = {
      Cmd = [ "/bin/app" ];
      Env = [ "NIX_REPRODUCIBLE=1" ];
    };
  }
