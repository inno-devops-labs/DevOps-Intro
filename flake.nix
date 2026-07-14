{
  description = "QuickNotes reproducible builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          quicknotes = pkgs.buildGo124Module {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;
            subPackages = [ "." ];
            CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
          };
          imageRoot = pkgs.runCommand "quicknotes-image-root" { } ''
            mkdir -p "$out/bin"
            mkdir -p "$out/tmp"
            chmod 1777 "$out/tmp"
            cp ${quicknotes}/bin/quicknotes "$out/bin/quicknotes"
            cp ${./app/seed.json} "$out/seed.json"
          '';
          dockerImage = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "lab11";
            created = "1970-01-01T00:00:01Z";
            copyToRoot = imageRoot;
            extraCommands = ''
              chmod 1777 tmp
            '';
            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "DATA_PATH=/tmp/data/notes.json"
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
          default = quicknotes;
          quicknotes = quicknotes;
          docker = dockerImage;
        });

      devShells = forAllSystems (system:
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
        });
    };
}
