{
  description = "My reproducible app";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.default = import ./default.nix { inherit pkgs; };
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [ pkgs.go pkgs.gopls ];
    };
  };
}
