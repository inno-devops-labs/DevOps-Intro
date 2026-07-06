{
  description = "Reproducible build of QuickNotes (Lab 11)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # QuickNotes has zero dependencies, so there is nothing to vendor.
            vendorHash = null;

            # Static, stripped, deterministic build.
            env.CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;

          # Deterministic OCI image built with Nix only — no Docker daemon.
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            # A fixed creation time keeps the digest reproducible.
            created = "1970-01-01T00:00:00Z";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };
            # World-writable /tmp so the nonroot process can persist state.
            extraCommands = "mkdir -p tmp && chmod 1777 tmp";
            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = { }; };
              User = "65532:65532";
              Env = [ "ADDR=:8080" "DATA_PATH=/tmp/notes.json" ];
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
