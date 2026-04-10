{
  description = "DevOps-Intro Lab 11 — reproducible Go app and Nix-built Docker image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = eachSystem (
        pkgs:
        let
          # Same as default.nix: native binary for the flake’s system (Task 1 style).
          default = pkgs.callPackage ./default.nix { };

          # Linux guest arch for Docker matches the machine Docker runs on this host.
          linuxGoArch = if pkgs.stdenv.hostPlatform.isx86_64 then "amd64" else "arm64";

          appLinux = pkgs.stdenv.mkDerivation rec {
            pname = "lab11-app";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ pkgs.go ];
            buildPhase = ''
              runHook preBuild
              export CGO_ENABLED=0
              export GOOS=linux
              export GOARCH=${linuxGoArch}
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

          docker = pkgs.dockerTools.buildLayeredImage {
            name = "lab11-app";
            tag = "nix";
            contents = [ appLinux ];
            created = "1970-01-01T00:00:00Z";
            config = {
              Cmd = [ "${appLinux}/bin/lab11-app" ];
            };
          };
        in
        {
          inherit default docker;
        }
      );

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.go
            pkgs.gopls
          ];
        };
      });
    };
}
