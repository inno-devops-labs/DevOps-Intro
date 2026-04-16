{
  description = "My reproducible app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # Use cross-compilation for Docker to run on a Linux container host
      linuxPkgs = pkgs.pkgsCross.aarch64-multiplatform;

      # Function to build the app, takes a specific package set
      buildApp = p: p.buildGoModule {
        pname = "lab11-app";
        version = "1.0.0";
        src = ./.;
        vendorHash = null;
      };

      app = buildApp pkgs;
      appLinux = buildApp linuxPkgs;
    in
    {
      # Default package builds the app for the local macOS architecture
      packages.${system}.default = app;

      # Docker image is built using the Linux version of the app
      packages.${system}.docker = pkgs.dockerTools.buildLayeredImage {
        name = "lab11-app-flake";
        tag = "latest";
        contents = [ appLinux ];
        config = {
          Cmd = [ "/bin/app" ];
        };
      };

      # Development environment with required tools
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.go pkgs.gopls ];
      };
    };
}
