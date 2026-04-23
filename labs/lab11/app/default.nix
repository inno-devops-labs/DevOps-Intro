{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "nix-app";
  version = "1.0.0";

  # Source is the current directory (all files are hashed as inputs)
  src = ./.;

  # Hash of Go module dependencies fetched via go mod download
  # Set to null since there are no external dependencies (stdlib only)
  vendorHash = null;

  meta = with pkgs.lib; {
    description = "Simple Go app demonstrating Nix reproducibility";
    license = licenses.mit;
  };
}
