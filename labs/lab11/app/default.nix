{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "reproducible-go-app";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  subPackages = [ "." ];

  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "A simple reproducible Go app built with Nix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}