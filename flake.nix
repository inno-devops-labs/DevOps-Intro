{
  description = "QuickNotes — reproducible build with Nix";

  # Pinned to an immutable nixos-25.05 commit (ships Go 1.24.10).
  # Pinning the input to a full commit rev guarantees every build — on any
  # machine or CI runner — resolves the exact same nixpkgs, so the two
  # parallel CI jobs cannot drift apart.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/ac62194c3917d5f474c1a844b6fd6da2db95077d";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];
        meta.mainProgram = "quicknotes";
      };
    in {
      packages.${system} = {
        inherit quicknotes;
        default = quicknotes;

        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:00Z";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532";
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/data/notes.json"
              "SEED_PATH=/seed.json"
            ];
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
