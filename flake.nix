{
  description = "Reproducible QuickNotes build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          buildGo124Module = pkgs.buildGoModule.override {
            go = pkgs.go_1_24;
          };

          quicknotes = buildGo124Module {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./app;
            vendorHash = null;

            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];

            postInstall = ''
              install -Dm0644 seed.json $out/share/quicknotes/seed.json
            '';
          };

          imageRoot = pkgs.buildEnv {
            name = "quicknotes-root";
            paths = [ quicknotes ];
            pathsToLink = [ "/bin" "/share" ];
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            created = "1970-01-01T00:00:01Z";

            copyToRoot = imageRoot;
            extraCommands = ''
              mkdir -m 1777 tmp
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/tmp/notes.json"
                "SEED_PATH=/share/quicknotes/seed.json"
              ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
              User = "65532:65532";
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.go_1_24
            pkgs.gopls
            pkgs.golangci-lint
          ];
        };
      });
    };
}
