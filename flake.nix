{
  description = "Reproducible builds of QuickNotes";

  # One input, one lock entry. flake.lock pins this to an exact nixpkgs
  # revision, which is what makes two builds on two machines comparable.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            # Only app/ is the source. Nothing else in the repository can
            # change the build result.
            src = ./app;

            # go.mod declares no dependencies, so there is nothing to vendor
            # and no vendor derivation to hash. null is the correct value
            # here, not a placeholder.
            vendorHash = null;

            # A static binary, the same choice as the Lab 6 Dockerfile.
            # It goes inside `env` because buildGoModule already places
            # CGO_ENABLED there, and a second copy as a plain derivation
            # argument is rejected as a duplicate.
            env.CGO_ENABLED = 0;

            # Drop the symbol table and the DWARF data. Smaller output, and
            # fewer places for build paths to hide.
            ldflags = [ "-s" "-w" ];

            # go test ./... runs inside the build, so a broken test fails the
            # package instead of shipping.
            doCheck = true;

            meta = {
              description = "QuickNotes, the course project service";
              mainProgram = "quicknotes";
            };
          };

          # The seed file has to be in the image, because the app reads it at
          # start to fill an empty store.
          seed = pkgs.runCommand "quicknotes-seed" { } ''
            mkdir -p $out
            cp ${./app/seed.json} $out/seed.json
          '';
        in
        {
          inherit quicknotes;
          default = quicknotes;

          # An OCI image built with no Docker involved. dockerTools writes the
          # tarball itself and sets every timestamp to the epoch, so the
          # digest depends only on the contents.
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            copyToRoot = [ quicknotes seed ];

            # The app needs one writable directory for its data file. The
            # image has no shell, so it is created here instead.
            extraCommands = ''
              mkdir -p tmp
              chmod 1777 tmp
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = { }; };
              # Numeric, because the image has no /etc/passwd to look a name
              # up in. Same user as the Lab 6 image.
              User = "65532:65532";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/tmp/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
