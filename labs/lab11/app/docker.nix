{ pkgs ? import <nixpkgs> { } }:

let
  appLinux = pkgs.stdenv.mkDerivation rec {
    pname = "lab11-app";
    version = "0.1.0";

    src = ./.;

    nativeBuildInputs = [
      pkgs.go
    ];

    buildPhase = ''
      runHook preBuild

      export CGO_ENABLED=0
      export GOOS=linux
      export GOARCH=arm64

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
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "lab11-app";
  tag = "nix";

  # Include the derivation output in the image (under /nix/store).
  contents = [
    appLinux
  ];

  # Avoid non-reproducible timestamps in the image config.
  created = "1970-01-01T00:00:00Z";

  config = {
    Cmd = [ "${appLinux}/bin/lab11-app" ];
  };
}

