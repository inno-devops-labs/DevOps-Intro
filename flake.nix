{
  description = "QuickNotes - reproducible build (DevOps-Intro Lab 11)";

  # Pinned channel. app/go.mod requires Go >= 1.24, so we need a channel whose
  # default buildGoModule ships at least that (nixos-24.11 only had Go 1.23).
  # flake.lock pins this to an exact revision — that lockfile is what makes the
  # build reproducible for anyone who clones the repo.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";

        # The Go module lives in app/ (that's where go.mod is), not the repo root.
        src = ./app;

        # app/go.mod declares ZERO third-party dependencies (pure stdlib) and
        # there is no go.sum, so there is nothing to vendor. `null` is the honest
        # value here — it tells buildGoModule to skip the vendor fetch entirely.
        vendorHash = null;

        # Fully static binary (no libc) - same discipline as the Lab 6 Dockerfile.
        env.CGO_ENABLED = 0;

        # Strip symbol table (-s) and DWARF (-w): smaller, and removes a source
        # of build-to-build variance.
        ldflags = [ "-s" "-w" ];

        meta.mainProgram = "quicknotes";
      };
    in
    {
      packages.${system} = {
        inherit quicknotes;
        default = quicknotes;

        # Task 2: an OCI image built by Nix — no Docker daemon, no `FROM`.
        # The image is exactly the runtime closure of the binary.
        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes-nix";
          tag = "0.1.0";

          # Determinism: a fixed creation timestamp instead of "now".
          # (This is dockerTools' default, but we state it explicitly.)
          created = "1970-01-01T00:00:00Z";

          # The scratch image has no /tmp; create one so the app can write its
          # data file as a non-root user.
          extraCommands = ''
            mkdir -p tmp
            chmod 1777 tmp
          '';

          config = {
            Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532"; # nonroot — same uid as Lab 6's distroless
            Env = [
              "ADDR=:8080"
              "DATA_PATH=/tmp/notes.json"
            ];
          };
        };
      };

      # `nix develop` drops collaborators into a shell with the pinned toolchain.
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
      };
    };
}
