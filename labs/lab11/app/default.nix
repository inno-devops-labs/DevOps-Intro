{ pkgs ? import <nixpkgs> { } }:

pkgs.buildGoModule rec {
  pname = "lab11-app";
  version = "0.1.0";

  src = ./.;

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "Lab 11 Go sample (stdlib only)";
    license = licenses.mit;
    # Matches $out/bin name from go.mod module path ("lab11/app" → "app"), not pname.
    mainProgram = "app";
  };
}
