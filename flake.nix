{
  description = "QuickNotes — reproducible build via Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;

          # go.mod has zero external dependencies, so there is nothing to vendor.
          vendorHash = null;

          env.CGO_ENABLED = 0;
          ldflags = [ "-s" "-w" ];

          meta = {
            description = "QuickNotes — a small Go JSON notes API";
            mainProgram = "quicknotes";
          };
        };
      in
      {
        packages = {
          default = quicknotes;
          quicknotes = quicknotes;
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
}
