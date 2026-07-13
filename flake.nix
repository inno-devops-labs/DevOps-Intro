{
  description = "QuickNotes — reproducible Go build + deterministic OCI image (Lab 11)";

  inputs = {
    # Channel pin; flake.lock freezes the exact nixpkgs revision (and thereby
    # the exact Go toolchain), so every clone builds with identical inputs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      # Binary + devShell build everywhere; the OCI image output is Linux-only
      # (a darwin-arch image tarball would be useless to Docker).
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # QuickNotes is stdlib-only: go.mod has zero require lines and no
            # go.sum exists, so there is nothing to vendor — null skips the
            # vendor derivation entirely. The moment a third-party dependency
            # appears, replace null with the `got: sha256-…` value that the
            # first failing build prints.
            vendorHash = null;

            env.CGO_ENABLED = "0";   # fully static binary, no libc reference
            ldflags = [ "-s" "-w" ]; # strip symbol table + DWARF (Lab 6 carry-over)
            # buildGoModule already passes -trimpath, removing absolute
            # build-directory paths from the binary.
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;
        }
        // nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";
            # Fixed timestamp → deterministic image config JSON. dockerTools
            # also normalizes every file mtime in the layer tar to this epoch,
            # which is exactly what SOURCE_DATE_EPOCH does for other tools.
            created = "1970-01-01T00:00:01Z";

            copyToRoot = pkgs.buildEnv {
              name = "quicknotes-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };

            # Runs while packing the image root — no Docker daemon involved.
            # /data must be writable by uid 65532; buildImage packs files as
            # root-owned without a VM, so a 0777 dir replaces Lab 6's chown.
            extraCommands = ''
              cp ${./app/seed.json} seed.json
              mkdir -p data
              chmod 0777 data
            '';

            config = {
              Entrypoint = [ "/bin/quicknotes" ]; # exec form
              ExposedPorts = { "8080/tcp" = { }; };
              User = "65532:65532";               # distroless "nonroot" uid:gid
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ go gopls golangci-lint ];
        };
      });
    };
}
