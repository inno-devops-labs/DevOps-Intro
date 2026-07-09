{
  description = "QuickNotes - a small Go notes API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Явно используем Go 1.24
        go = pkgs.go_1_24;
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";

          src = ./app;

          vendorHash = null;
          subPackages = [ "." ];

          ldflags = [ "-s" "-w" ];

          env = {
    		CGO_ENABLED = "0";
  	  };

          meta = {
            description = "QuickNotes - a small Go notes API";
            license = pkgs.lib.licenses.mit;
          };
        };

        packages.quicknotes = self.packages.${system}.default;

        devShell = pkgs.mkShell {
          buildInputs = [
            go
            pkgs.gopls
            pkgs.golangci-lint
          ];
        };
      }
    );
}