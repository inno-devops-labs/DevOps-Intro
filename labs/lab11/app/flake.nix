{
  description = "Reproducible app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in {
    packages.x86_64-linux.default = pkgs.buildGoModule {
      pname = "app";
      version = "1.0";
      src = ./.;
      vendorHash = "sha256-XXXX";
    };
  };
}
