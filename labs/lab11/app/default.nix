{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "lab11-app";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ pkgs.go ];
  dontConfigure = true;

  # Make Go build deterministic and independent from host machine metadata.
  buildPhase = ''
    export HOME="$TMPDIR"
    export CGO_ENABLED=0
    export GOFLAGS="-trimpath -mod=readonly -buildvcs=false"
    go build -ldflags="-s -w -buildid=" -o app ./main.go
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 app "$out/bin/app"
  '';
}
