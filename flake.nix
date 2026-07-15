{
  description = "Go example flake for Zero to Nix";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs }:
        let
          quicknotes = pkgs.buildGoModule {
            name = "quicknotes";
            src = ./app;
            vendorHash = null;
            env.CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
          };

          # Docker images are always Linux; cross-compile explicitly rather than
          # reusing `quicknotes`, which targets the host's own OS (may be Darwin).
          quicknotesLinux = quicknotes.overrideAttrs (old: {
            env = (old.env or { }) // {
              GOOS = "linux";
              GOARCH = "amd64";
            };
            doCheck = false; # cross-compiled test binary can't run on the build host
          });

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "quicknotes-root";
              paths = [ quicknotesLinux ];
              pathsToLink = [ "/bin" ];
            };
            # /data must be writable by the nonroot user, and the seed file
            # needs to live somewhere readable without a bind mount.
            extraCommands = ''
              mkdir -p data
              chmod 0777 data
              cp ${./app/seed.json} seed.json
            '';
            config = {
              Entrypoint = [ "/bin/linux_amd64/quicknotes" ];
              ExposedPorts = {
                "8080/tcp" = { };
              };
              Env = [
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
              User = "65532:65532";
            };
          };
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        }
      );

      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${pkgs.system}.default ];
            packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
          };
        }
      );
    };
}
