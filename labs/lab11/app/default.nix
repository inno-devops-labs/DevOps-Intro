{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation rec {
  pname = "lab11-app";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    pkgs.go
  ];

  # Small Go program; uses go.mod (stdlib only) for Go 1.22+ module mode.
  buildPhase = ''
    runHook preBuild
    export CGO_ENABLED=0
    export HOME="$TMPDIR"
    export GOCACHE="$TMPDIR/go-build"
    go build -trimpath -ldflags="-s -w" -o lab11-app .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 0755 lab11-app "$out/bin/lab11-app"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "DevOps-Intro lab11 Go app";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
