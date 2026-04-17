{
  description = "Lab 11 reproducible builds with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      app = pkgs.stdenv.mkDerivation {
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
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "lab11-app-flake";
        tag = "latest";
        contents = [ app ];
        config.Cmd = [ "/bin/app" ];
      };
    in {
      packages.${system} = {
        default = app;
        dockerImage = dockerImage;
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls ];
        };
      };
    };
}
