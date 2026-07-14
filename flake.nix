{
  description = "Reproducible QuickNotes build with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = system: import nixpkgs {
        inherit system;
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./.;
            modRoot = "app";

            # QuickNotes has no external Go module dependencies to vendor.
            vendorHash = null;

            env = {
              CGO_ENABLED = "0";
            };

            ldflags = [
              "-s"
              "-w"
            ];

            meta = {
              mainProgram = "quicknotes";
            };
          };

          quicknotesRoot = pkgs.runCommand "quicknotes-root" {} ''
            mkdir -p $out/bin

            cp ${quicknotes}/bin/quicknotes $out/bin/quicknotes

            chmod 0555 $out/bin
            chmod 0555 $out/bin/quicknotes
          '';

          quicknotesImage = pkgs.dockerTools.buildImage {
            name = "quicknotes-nix";
            tag = "0.1.0";

            created = "1970-01-01T00:00:01Z";

            copyToRoot = quicknotesRoot;

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = {
                "8080/tcp" = {};
              };
              User = "65532:65532";
              WorkingDir = "/";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/dev/shm/notes.json"
                "SEED_PATH=/dev/shm/seed.json"
              ];
            };
          };
        in
        {
          quicknotes = quicknotes;
          default = quicknotes;
          docker = quicknotesImage;
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              golangci-lint
            ];
          };
        });
    };
}