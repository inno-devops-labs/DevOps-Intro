{
  description = "My test app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      app = pkgs.buildGoModule {
        pname = "hello-go";
        version = "0.1.0";
        src = ./.;
        vendorHash = null;
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "hello-go";
        tag = "0.1.0";
        contents = [ app ];
        config = {
          Cmd = [ "/bin/hello-go" ];
        };
      };
    in {
      packages.${system}.default = app;
      dockerImages.${system}.default = dockerImage;
    };
}