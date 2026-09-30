{
  description = "QuickNotes reproducible build";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        env.CGO_ENABLED = "0";
        ldflags = [ "-s" "-w" ];
      };
      imageRoot = pkgs.runCommand "quicknotes-image-root" { } ''
        mkdir -p "$out/bin" "$out/tmp"
        ln -s "${quicknotes}/bin/quicknotes" "$out/bin/quicknotes"
        chmod 1777 "$out/tmp"
      '';
      docker = pkgs.dockerTools.buildImage {
        name = "quicknotes-nix";
        tag = "lab11";
        created = "1970-01-01T00:00:01Z";
        copyToRoot = imageRoot;
        config = {
          User = "65532:65532";
          Entrypoint = [ "/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = { }; };
          Env = [ "DATA_PATH=/dev/shm/notes.json" "SEED_PATH=/tmp/seed.json" ];
        };
      };
    in {
      packages.${system} = {
        inherit quicknotes docker;
        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
