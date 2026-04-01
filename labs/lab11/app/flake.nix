{
  description = "Reproducible Go app with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      app = pkgs.buildGoModule {
        pname = "nix-lab-app";
        version = "1.0.0";
        src = ./.;
        vendorHash = null;
      };
    in {
      packages.${system}.default = app;

      dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "nix-lab-app";
        tag = "latest";
        contents = [ app ];
        config.Cmd = [ "${app}/bin/nix-lab-app" ];
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
