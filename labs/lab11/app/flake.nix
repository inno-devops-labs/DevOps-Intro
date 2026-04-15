{
  description = "Lab 11 reproducible Go app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      app = pkgs.callPackage ./default.nix { };
      dockerImage = pkgs.callPackage ./docker.nix { };
    in
    {
      packages.${system}.default = app;
      dockerImages.${system}.default = dockerImage;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.go
          pkgs.gopls
        ];
      };
    };
}
