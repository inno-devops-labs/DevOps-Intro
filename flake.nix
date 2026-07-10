{
  description = "QuickNotes reproducible builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          quicknotes = pkgs.buildGo124Module {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./app;
            vendorHash = null;

            env.CGO_ENABLED = 0;
            ldflags = [
              "-s"
              "-w"
            ];
          };

          imageRoot = pkgs.runCommand "quicknotes-image-root" { } ''
            mkdir -p "$out/bin" "$out/data"
            cp ${quicknotes}/bin/quicknotes "$out/bin/quicknotes"
            cp ${./app/seed.json} "$out/seed.json"
            chmod 0555 "$out/bin/quicknotes"
            chmod 0777 "$out/data"
          '';
        in
        {
          inherit quicknotes;

          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            copyToRoot = imageRoot;
            uid = 65532;
            gid = 65532;
            extraCommands = ''
              chmod 0777 data
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
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              golangci-lint
            ];
          };
        }
      );
    };
}
