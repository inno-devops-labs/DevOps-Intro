{
  description = "Reproducible Go app with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      
      app = pkgs.buildGoModule {
        pname = "app";
        version = "0.1.0";
        src = ./.;
        vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        doCheck = false;
      };
    in
    {
      packages.${system}.default = app;
      
      dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "nix-app";
        contents = [ app ];
        config.Entrypoint = [ "${app}/bin/app" ];
      };
      
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}