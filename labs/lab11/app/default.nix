{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "nix-lab-app";
  version = "1.0.0";

  src = ./.;

  # No external dependencies, so vendorHash is null
  vendorHash = null;

  meta = with pkgs.lib; {
    description = "Simple Go app for Nix reproducibility lab";
    license = licenses.mit;
  };
}
