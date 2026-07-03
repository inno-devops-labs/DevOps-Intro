{
  description = "QuickNotes reproducible builds with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;

        vendorHash = null;

        env.CGO_ENABLED = "0";
        ldflags = [ "-s" "-w" ];
      };

      quicknotesRoot = pkgs.runCommand "quicknotes-root" { } ''
        mkdir -p "$out/bin" "$out/tmp"
        ln -s "${quicknotes}/bin/quicknotes" "$out/bin/quicknotes"
        cp "${./app/seed.json}" "$out/seed.json"
        chmod 1777 "$out/tmp"
      '';

      quicknotesImage = pkgs.dockerTools.buildImage {
        name = "quicknotes-nix";
        tag = "v0.1.0";

        copyToRoot = quicknotesRoot;

        extraCommands = ''
          mkdir -p tmp
          chmod 1777 tmp
        '';

        config = {
          Entrypoint = [ "/bin/quicknotes" ];
          Env = [
            "ADDR=:8080"
            "DATA_PATH=/tmp/notes.json"
            "SEED_PATH=/seed.json"
          ];
          ExposedPorts = {
            "8080/tcp" = { };
          };
          User = "65532:65532";
        };
      };
    in {
      packages.${system} = {
        quicknotes = quicknotes;
        default = quicknotes;
        docker = quicknotesImage;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.go
          pkgs.gopls
          pkgs.golangci-lint
        ];
      };
    };
}
