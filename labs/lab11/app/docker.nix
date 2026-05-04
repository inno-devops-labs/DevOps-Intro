{ pkgs ? import <nixpkgs> { } }:

let
  lab11-app = import ./default.nix { inherit pkgs; };
in

pkgs.dockerTools.buildLayeredImage {
  name = "lab11-app";
  tag = "latest";

  contents = [
    lab11-app
  ];

  config = {
    # Exact store path to the Go binary from the Task 1 derivation (reproducible).
    Cmd = [
      (pkgs.lib.getExe lab11-app)
    ];
    # Do not set created = "now"; it fixes image metadata to the build wall-clock time
    # and breaks bitwise reproducibility of the artifact.
  };
}
