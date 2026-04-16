{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
    pname = "lab11-go-app";
    version = "1.0.0";

    src = ./.;

    nativeBuildInputs = [ pkgs.go ];

    buildPhase = ''
        runHook preBuild

        export HOME="$TMPDIR"
        export GOPATH="$TMPDIR/go"
        export GOCACHE="$TMPDIR/go-build"
        export GOMODCACHE="$TMPDIR/go-mod"

        export GO111MODULE=off
        export CGO_ENABLED=0

        go build -trimpath -ldflags="-s -w" -o lab11-app main.go

        runHook postBuild
    '';

    installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp lab11-app $out/bin/
        runHook postInstall
    '';

    meta = with pkgs.lib; {
        description = "A tiny Go program";
        license = licenses.mit;
        platforms = platforms.linux;
    };
}