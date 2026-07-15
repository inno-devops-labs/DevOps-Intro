{
  description = "QuickNotes — reproducible builds with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go = pkgs.go_1_24;
        buildGoModule = pkgs.buildGoModule.override { inherit go; };
      in
      {
        packages.default = self.packages.${system}.quicknotes;

        packages.quicknotes = buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;
          vendorHash = null;   # проект не имеет внешних зависимостей
          ldflags = [ "-s" "-w" ];
          subPackages = [ "." ];
          env.CGO_ENABLED = "0";
        };

        packages.docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "latest";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ self.packages.${system}.quicknotes ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Cmd = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = {}; };
            User = "1000:1000";   # nonroot
          };
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            go_1_24
            gopls
            golangci-lint
          ];
        };
      }
    );
}
