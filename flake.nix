{
  description = "QuickNotes — reproducible Go binary and OCI image (Lab 11)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;

          vendorHash = null;

          # nixos-24.11 ships Go 1.23; patch only inside the Nix sandbox.
          postPatch = ''
            substituteInPlace go.mod --replace-fail 'go 1.24' 'go 1.23'
          '';

          CGO_ENABLED = 0;
          ldflags = [ "-s" "-w" ];
        };

        imageRoot = pkgs.runCommand "quicknotes-image-root" {} ''
          mkdir -p $out/data
          cp ${quicknotes}/bin/quicknotes $out/quicknotes
          cp ${./app/seed.json} $out/seed.json
        '';
      in {
        packages.quicknotes = quicknotes;
        packages.default = quicknotes;

        packages.docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          # CI red demo: job A sets SOURCE_DATE_EPOCH=0 and runs `nix build --impure`.
          # Pure builds (green) ignore host env and keep the nixpkgs default second.
          created =
            if builtins.getEnv "SOURCE_DATE_EPOCH" == "0" then
              "1970-01-01T00:00:00Z"
            else
              "1970-01-01T00:00:01Z";
          copyToRoot = imageRoot;
          config = {
            Entrypoint = [ "/quicknotes" ];
            ExposedPorts = { "8080/tcp" = {}; };
            User = "65532:65532";
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/data/notes.json"
              "SEED_PATH=/seed.json"
            ];
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go_1_24
            gopls
            golangci-lint
          ];
        };
      });
}
