{ pkgs ? import <nixpkgs> {} }:

let
  helloBinary = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "hello-nix";
  tag = "reproducible";
  
  contents = [ helloBinary pkgs.coreutils pkgs.bash ];
  
  config = {
    Cmd = [ "/bin/hello" ];
    Env = [ "NIX_REPRODUCIBLE=1" ];
  };
}
