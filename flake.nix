{
  description = "QuickNotes reproducible builds for DevOps-Intro Lab 11";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./app;
            vendorHash = null;

            env.CGO_ENABLED = 0;
            ldflags = [
              "-s"
              "-w"
            ];

            doCheck = true;
          };

          quicknotesRoot = pkgs.runCommand "quicknotes-root" { } ''
            mkdir -p "$out/bin"
            cp "${quicknotes}/bin/quicknotes" "$out/bin/quicknotes"
            cp "${./app/seed.json}" "$out/seed.json"
            chmod 0555 "$out/bin" "$out/bin/quicknotes"
          '';

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix-lab11";

            copyToRoot = quicknotesRoot;
            extraCommands = ''
              mkdir -p data
              chmod 1777 data
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
              User = "65532:65532";
              WorkingDir = "/";
            };
          };
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.go_1_24
              pkgs.gopls
              pkgs.golangci-lint
            ];
          };
        }
      );
    };
}
