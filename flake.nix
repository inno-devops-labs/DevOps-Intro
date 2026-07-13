{
  description = "QuickNotes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;

        vendorHash = null;

        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];
      };
    in
    {
      packages.${system} = {
        quicknotes = quicknotes;
        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
      };
    };
}