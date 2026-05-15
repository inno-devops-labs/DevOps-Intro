{
  description = "Lab 11 reproducible Go app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      app = pkgs.buildGoModule {
        pname = "app";
        version = "1.0.0";
        src = pkgs.lib.cleanSource ./.;
        vendorHash = null;
      };
      image = pkgs.dockerTools.buildLayeredImage {
        name = "nix-app-flake";
        tag = "latest";
        contents = [ app ];
        config = {
          Cmd = [ "${app}/bin/app" ];
        };
      };
    in {
      packages.${system}.default = app;
      dockerImages.${system}.default = image;
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.go
          pkgs.gopls
        ];
      };
    };
}
