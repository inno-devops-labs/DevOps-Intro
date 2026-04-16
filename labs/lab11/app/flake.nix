{
  description = "My reproducible Go app with Flakes";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    packages.${system}.default = pkgs.buildGoModule {
      pname = "nix-go-app"; version = "1.0.0"; src = ./.; vendorHash = null;
    };
    dockerImages.${system}.default = pkgs.dockerTools.buildLayeredImage {
      name = "nix-go-app-image"; tag = "latest";
      contents = [ self.packages.${system}.default ];
      config.Cmd = [ "${self.packages.${system}.default}/bin/myapp" ];
    };
    devShells.${system}.default = pkgs.mkShell { buildInputs = [ pkgs.go pkgs.gopls ]; };
  };
}
