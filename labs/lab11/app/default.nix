{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "lab11-app";
  version = "0.1.0";
  
  src = ./.;
  
  vendorHash = null; 
  
  meta = with pkgs.lib; {
    description = "Lab 11 Nix reproducible build demo";
    homepage = "https://github.com/mnkhmtv/DevOps-Intro";
  };
}
