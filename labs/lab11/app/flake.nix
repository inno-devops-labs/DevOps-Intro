{
  description = "Reproducible Go app demonstrating Nix Flakes";

  inputs = {
    # Pin nixpkgs to a specific release for maximum reproducibility
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Default package: the Go binary
        packages.default = pkgs.buildGoModule {
          pname = "nix-app";
          version = "1.0.0";
          src = ./.;
          vendorHash = null;
        };

        # Docker image as a separate output
        packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "nix-app";
          tag = "latest";
          contents = [ self.packages.${system}.default ];
          config.Cmd = [ "/bin/app" ];
        };

        # Reproducible development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.go pkgs.gopls pkgs.gotools ];
          shellHook = ''
            echo "Nix dev shell ready — Go $(go version)"
          '';
        };
      });
}
