{ pkgs ? import <nixpkgs> {} }:

let
	goApp = pkgs.callPackage ./default.nix {};
in
pkgs.dockerTools.buildLayeredImage {
	name = "lab11-go-app";
	tag = "1.0.0";

	contents = [ goApp ];

	config = {
		Cmd = [ "${goApp}/bin/lab11-app" ];
	};
}
