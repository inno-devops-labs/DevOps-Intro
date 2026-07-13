{
  description = "QuickNotes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;

        vendorHash = null;

        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];
      };

      dockerImage = pkgs.dockerTools.buildImage {
        name = "quicknotes";

        config = {
          Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = {}; };
          User = "65532:65532";
        };
      };

    in
    {
      packages.${system} = {
        quicknotes = quicknotes;
        default = quicknotes;
        docker = dockerImage;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
      };
    };
}