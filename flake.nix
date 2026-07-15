{
  description = "QuickNotes: reproducible Go build + OCI image (DevOps-Intro Lab 11)";

  inputs = {
    # Pinned channel; nixos-25.11 ships Go >= 1.24 as the default toolchain,
    # which app/go.mod requires. The exact revision is locked in flake.lock.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # QuickNotes has no third-party Go dependencies (go.mod has no
            # require block), so there is no vendor tree to hash. The first
            # build with a placeholder hash fails with:
            #   "vendor folder is empty, please set 'vendorHash = null;'"
            # null skips the fixed-output vendor derivation entirely; builds
            # are network-isolated regardless, so nothing is left unpinned.
            vendorHash = null;

            # Static binary: no cgo, no libc, runs on scratch/distroless.
            # (This nixpkgs revision keeps CGO_ENABLED inside `env`, so it
            # must be set there; a top-level attr collides.)
            env.CGO_ENABLED = 0;

            # Strip symbol table + DWARF (carried over from Lab 6).
            # buildGoModule already passes -trimpath by itself.
            ldflags = [ "-s" "-w" ];
          };
          # Deterministic OCI image, built by Nix alone (no Docker daemon,
          # no FROM). Contents: the static quicknotes closure + the few
          # files created in extraCommands.
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "lab11";

            copyToRoot = quicknotes;

            # Filesystem extras, packed into the single layer as uid 0.
            # /etc/passwd + /etc/group define the nonroot user (65532,
            # same as distroless in Lab 6). /data is world-writable so the
            # nonroot app can seed notes.json when no volume is mounted;
            # in real deployments a volume mounts over it (Lab 6 compose).
            extraCommands = ''
              mkdir -p data etc
              chmod 0777 data
              printf 'root:x:0:0:root:/root:/sbin/nologin\nnonroot:x:65532:65532:nonroot:/:/sbin/nologin\n' > etc/passwd
              printf 'root:x:0:\nnonroot:x:65532:\n' > etc/group
              cp ${./app/seed.json} seed.json
            '';

            # Fixed creation time (the buildImage default, made explicit):
            # wall-clock time must not leak into the image metadata.
            created = "1970-01-01T00:00:01Z";

            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts."8080/tcp" = { };
              User = "nonroot:nonroot";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ go gopls golangci-lint ];
        };
      });
    };
}
