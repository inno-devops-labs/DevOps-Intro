{
  description = "QuickNotes — reproducible builds with Nix (DevOps-Intro Lab 11)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;
            CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
            subPackages = [ "." ];
          };

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "0.1.0";
            copyToRoot = [ quicknotes ];
            extraCommands = ''
              cp ${./app/seed.json} seed.json
              mkdir -p data && chmod 0777 data
            '';
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
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
