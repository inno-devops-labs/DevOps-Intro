{
  description = "QuickNotes — reproducible Nix flake (Lab 11)";

  inputs = {
    # nixos-24.11 ships Go 1.23; QuickNotes go.mod requires >= 1.24.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkQuicknotes =
        pkgs:
        pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";

          src = pkgs.lib.cleanSourceWith {
            src = ./app;
            filter =
              path: type:
              let
                base = baseNameOf path;
              in
              !(builtins.elem base [
                "quicknotes"
                "data"
                "result"
              ]);
          };

          # Stdlib-only module: no Go deps to vendor.
          # nixos-25.05 buildGoModule requires vendorHash = null when the vendor tree is empty
          # (a non-null empty hash fails with "vendor folder is empty").
          vendorHash = null;

          env.CGO_ENABLED = "0";
          ldflags = [
            "-s"
            "-w"
          ];

          meta = {
            description = "QuickNotes HTTP notes API";
            mainProgram = "quicknotes";
          };
        };

      # Minimal passwd/group so the container can run as Lab 6's nonroot UID 65532.
      nonrootPasswd = pkgs: ''
        root:x:0:0::/root:/sbin/nologin
        nonroot:x:65532:65532::/home/nonroot:/sbin/nologin
        nobody:x:65534:65534::/:/sbin/nologin
      '';
      nonrootGroup = pkgs: ''
        root:x:0:
        nonroot:x:65532:
        nogroup:x:65534:
      '';

      mkDocker =
        pkgs: quicknotes:
        pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "lab11";
          copyToRoot = pkgs.buildEnv {
            name = "quicknotes-image-root";
            paths = [
              quicknotes
              pkgs.dockerTools.caCertificates
              (pkgs.writeTextDir "etc/passwd" (nonrootPasswd pkgs))
              (pkgs.writeTextDir "etc/group" (nonrootGroup pkgs))
            ];
            pathsToLink = [
              "/bin"
              "/etc"
            ];
          };
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = { };
            };
            User = "65532:65532";
            Env = [
              "ADDR=0.0.0.0:8080"
              "DATA_PATH=/tmp/notes.json"
              "SEED_PATH=/seed.json"
            ];
            WorkingDir = "/";
          };
          extraCommands = ''
            mkdir -p -m 1777 tmp
            cp ${./app/seed.json} seed.json
          '';
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          quicknotes = mkQuicknotes pkgs;
          docker = mkDocker pkgs quicknotes;
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.go
              pkgs.gopls
              pkgs.golangci-lint
            ];
          };
        }
      );
    };
}
