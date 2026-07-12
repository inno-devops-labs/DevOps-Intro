{
  description = "QuickNotes — reproducible build with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
        CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" "-trimpath" ];
        meta.mainProgram = "quicknotes";
      };
    in {
      packages.${system} = {
        inherit quicknotes;

        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:00Z";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes pkgs.cacert ];
            pathsToLink = [ "/bin" "/etc" ];
          };
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = {}; };
            User = "65532:65532";
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/data/notes.json"
              "SEED_PATH=/seed.json"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };

        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          gopls
          golangci-lint
        ];
      };
    };
}
