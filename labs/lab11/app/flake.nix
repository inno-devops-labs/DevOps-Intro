{
  description = "Reproducible Go app with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    app = pkgs.buildGoModule {
      pname = "app";
      version = "1.0";

      src = ./.;

      vendorHash = null;

      subPackages = [ "." ];
    };

  in {
    packages.${system}.default = app;

    dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
      name = "nix-app";
      tag = "latest";

      contents = [ app ];

      config = {
        Cmd = [ "/bin/app" ];
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.go
        pkgs.gopls
      ];
    };
  };
}
