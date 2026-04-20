{
  description = "Lab 11 reproducible builds with Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      app = pkgs.buildGoModule {
        pname = "reproducible-go-app";
        version = "1.0.0";
        src = ./.;
        vendorHash = null;
        subPackages = [ "." ];
        ldflags = [ "-s" "-w" ];
      };
    in {
      packages.${system}.default = app;

      dockerImages.${system}.default = pkgs.dockerTools.buildImage {
        name = "nix-repro-app";
        tag = "latest";

        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ app ];
          pathsToLink = [ "/bin" ];
        };

        config = {
          Cmd = [ "/bin/reproducible-go-app" ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
