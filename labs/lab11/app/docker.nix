{ pkgs ? import <nixpkgs> {} }:

let
  app = import ./default.nix { inherit pkgs; };
in

pkgs.dockerTools.buildLayeredImage {
  name = "nix-app";
  tag = "latest";

  # Contents: our app binary plus minimal runtime dependencies
  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
    # No 'created = "now"' — omitting this keeps the image reproducible.
    # The default epoch timestamp ensures identical image hashes across builds.
  };
}
