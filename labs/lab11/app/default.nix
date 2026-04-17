{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "app";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ pkgs.go ];

  buildPhase = ''
    export HOME=$TMPDIR
    export GOCACHE=$TMPDIR/go-cache
    export CGO_ENABLED=0
    export SOURCE_DATE_EPOCH=1
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o app .
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp app $out/bin/app
  '';
}
