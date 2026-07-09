{
  description = "QuickNotes — reproducible Go build + deterministic OCI image (Lab 11)";

  # flake.lock pins this to an exact nixpkgs revision → the single source of
  # reproducibility across machines.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        # QuickNotes has zero third-party deps, so there is nothing to vendor.
        vendorHash = null;
        CGO_ENABLED = 0;              # static binary
        ldflags = [ "-s" "-w" ];      # strip (size + reproducibility); -trimpath is default
      };
    in
    {
      packages.${system} = {
        default = quicknotes;
        quicknotes = quicknotes;

        # Deterministic OCI image built by Nix (no Docker daemon involved).
        # dockerTools.buildImage pins layer timestamps to the epoch, so two
        # independent builds produce an identical tarball digest.
        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes-nix";
          tag = "latest";
          # minimal image has no /tmp; the nonroot app writes DATA_PATH there
          extraCommands = "mkdir -p tmp && chmod 1777 tmp";
          config = {
            Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65534:65534";     # nobody:nobody — nonroot (Lab 6 discipline)
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/tmp/notes.json"
              "SEED_PATH=/seed.json"
            ];
          };
        };
      };

      # `nix develop` drops collaborators into a shell with the Go toolchain.
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
      };
    };
}
