{
  description = "Reproducible QuickNotes: static Go binary + deterministic OCI image";

  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;
            env.CGO_ENABLED = "0"; # static binary (carried from lab 6)
            ldflags = [ "-s" "-w" ]; # size + reproducibility (carried from lab 6)
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes-nix";
            tag = "lab11";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };
            extraCommands = ''
              mkdir -p data tmp
              chmod 0777 data tmp
              cp ${./app/seed.json} seed.json
            '';
            config = {
              Entrypoint = [ "/bin/quicknotes" ]; # exec form
              ExposedPorts."8080/tcp" = { };
              User = "65532:65532"; # nonroot, lab 6 discipline
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
