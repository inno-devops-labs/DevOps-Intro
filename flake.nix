{
  description = "QuickNotes — reproducible builds with Nix";

  inputs = {
    # Pinned channel. nixos-25.05 ships go_1_24, which app/go.mod needs (>= 1.24).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Force Go 1.24 regardless of the channel default (app/go.mod requires >= 1.24).
        go = pkgs.go_1_24;
        buildGoModule = pkgs.buildGoModule.override { inherit go; };

        quicknotes = buildGoModule {
          pname = "quicknotes";
          version = "1.0.0";
          src = ./app;

          # QuickNotes has zero third-party dependencies (no go.sum),
          # so there is no vendor tree to hash.
          vendorHash = null;

          # Static binary (distroless/scratch-friendly), carried from Lab 6.
          CGO_ENABLED = 0;
          ldflags = [ "-s" "-w" ];
          # buildGoModule already passes -trimpath.

          doCheck = false; # tests are gated in Lab 3 CI
        };

        # seed.json placed at image root /seed.json
        seed = pkgs.runCommand "quicknotes-seed" { } ''
          mkdir -p $out
          cp ${./app/seed.json} $out/seed.json
        '';

        # Deterministic OCI image, built WITHOUT Docker (only Nix).
        # `created` pinned to a fixed epoch so the digest is reproducible.
        dockerImage = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "nix";
          created = "1970-01-01T00:00:01Z";
          copyToRoot = [ quicknotes seed ];
          # Give the nonroot user a writable /tmp (DATA_PATH lives there).
          # Without this the image loads but the process cannot create
          # /tmp/notes.json and exits on startup.
          extraCommands = ''
            mkdir -p tmp
            chmod 1777 tmp
          '';
          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532"; # nonroot, matching Lab 6
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/tmp/notes.json"
              "SEED_PATH=/seed.json"
            ];
          };
        };
      in {
        packages = {
          quicknotes = quicknotes;
          default = quicknotes;
          docker = dockerImage;
        };

        devShells.default = pkgs.mkShell {
          packages = [ go pkgs.gopls pkgs.golangci-lint ];
        };
      });
}
