{
  description = "Reproducible QuickNotes build and OCI image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          buildGoModule = pkgs.buildGoModule.override { go = pkgs.go_1_24; };

          quicknotesSrc = lib.cleanSourceWith {
            src = ./app;
            filter =
              path: type:
              let
                name = baseNameOf path;
              in
              type == "directory"
              || lib.hasSuffix ".go" name
              || name == "go.mod"
              || name == "go.sum"
              || name == "seed.json";
          };

          quicknotes = buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            src = quicknotesSrc;
            subPackages = [ "." ];

            env.CGO_ENABLED = "0";
            ldflags = [
              "-s"
              "-w"
            ];

            vendorHash = null;

            postInstall = ''
              install -Dm0644 seed.json $out/share/quicknotes/seed.json
            '';
          };

          quicknotesRoot = pkgs.buildEnv {
            name = "quicknotes-root";
            paths = [ quicknotes ];
            pathsToLink = [
              "/bin"
              "/share"
            ];
          };
        in
        {
          quicknotes = quicknotes;
          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            created = "1970-01-01T00:00:01Z";

            copyToRoot = quicknotesRoot;

            extraCommands = ''
              mkdir -p data tmp
              chmod 0777 data
              chmod 1777 tmp
            '';

            config = {
              User = "65532:65532";
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/share/quicknotes/seed.json"
              ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
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
