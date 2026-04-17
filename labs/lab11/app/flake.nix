{
  description = "Lab 11 reproducible builds with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = builtins.currentSystem;
      pkgs = import nixpkgs { inherit system; };

      app = pkgs.buildGoModule {
        pname = "app";
        version = "1.0.0";
        src = ./labs/lab11/app;
        vendorHash = null;
        ldflags = [ "-s" "-w" ];
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "nix-app";
        tag = "latest";
        contents = [ app ];
        config = {
          Cmd = [ "/bin/app" ];
        };
      };
    in {
      packages.${system}.default = app;
      packages.${system}.dockerImage = dockerImage;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
