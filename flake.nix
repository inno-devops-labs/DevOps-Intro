{
  description = "QuickNotes — reproducible Nix build (Lab 11)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
          });

      mkQuicknotes = pkgs: pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        env.CGO_ENABLED = "0";
        ldflags = [ "-s" "-w" ];
      };

      mkDocker = pkgs: quicknotes:
        pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          copyToRoot = pkgs.buildEnv {
            name = "quicknotes-image-root";
            paths = [
              quicknotes
              (pkgs.linkFarm "quicknotes-seed" [
                { name = "seed.json"; path = ./app/seed.json; }
              ])
            ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65534";
          };
        };
    in {
      packages = eachSystem ({ pkgs }:
        let
          quicknotes = mkQuicknotes pkgs;
        in {
          default = quicknotes;
          inherit quicknotes;
          docker = mkDocker pkgs quicknotes;
        });

      devShells = eachSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ go gopls golangci-lint ];
        };
      });
    };
}
