{ pkgs ? import <nixpkgs> {} }:

let
  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let
        base = builtins.baseNameOf path;
      in
      !(base == "result" || pkgs.lib.hasPrefix "result-" base);
  };
in
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  inherit src;

  vendorHash = null;

  subPackages = [ "." ];

  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "Simple reproducible Go app for Lab 11";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
