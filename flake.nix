{
  description = "Reproducible QuickNotes with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          buildGoModuleWithGo124 = pkgs.buildGoModule.override { go = pkgs.go_1_24; };
        in {
          default = buildGoModuleWithGo124 {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;
            CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
          };
          quicknotes = self.packages.${system}.default;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "v0.1.0";
            copyToRoot = [ self.packages.${system}.default ];
            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = {}; };
              User = "10001:10001";
            };
          };
        }
      );

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.go_1_24 pkgs.gopls pkgs.golangci-lint ];
          };
        }
      );
    };
}
