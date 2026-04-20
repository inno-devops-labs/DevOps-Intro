{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "app";
  version = "1.0";

  src = ./.;

  buildInputs = [ pkgs.go ];

  buildPhase = ''
    export HOME=$TMPDIR
    export GOCACHE=$TMPDIR/go-cache

    go build -o app main.go
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp app $out/bin/
  '';
}