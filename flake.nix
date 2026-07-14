{
  description = "QuickNotes - reproducible Go build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;

          vendorHash = null;

          env.CGO_ENABLED = 0;

          ldflags = [ "-s" "-w" ];

          meta = {
            description = "QuickNotes API server";
            mainProgram = "quicknotes";
          };
        };

        default = self.packages.${system}.quicknotes;

        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "0.1.0";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ self.packages.${system}.quicknotes ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = { };
            };
            User = "65532:65532";
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.go
          pkgs.gopls
          pkgs.golangci-lint
        ];
      };
    };
}