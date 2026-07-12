{
  description = "QuickNotes — reproducible build with Nix (Lab 11)";

  # Pinned to a channel branch; flake.lock freezes the exact revision so every
  # clone resolves the identical nixpkgs — the load-bearing file for repro.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Task 1 — the static Go binary, built from ./app.
      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        # QuickNotes has zero external dependencies (no go.sum) — nothing to
        # vendor, so the vendor hash is null. See design question (b).
        vendorHash = null;
        CGO_ENABLED = 0; # static binary, no libc
        ldflags = [ "-s" "-w" ]; # strip symbols + DWARF (size + repro)
        # buildGoModule + Nix already give a deterministic, timestamp-free build.
      };

      # Task 2 — a deterministic OCI image, built with Nix (no Docker).
      dockerImage = pkgs.dockerTools.buildImage {
        name = "quicknotes";
        tag = "nix";
        # No `created` timestamp is set -> defaults to the Unix epoch, so the
        # digest is stable across builds (see design question e).
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ quicknotes ];
          pathsToLink = [ "/bin" ];
        };
        # A world-writable /tmp so the nonroot app can persist notes.json.
        extraCommands = "mkdir -m 1777 tmp";
        config = {
          Entrypoint = [ "/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = { }; };
          Env = [ "ADDR=:8080" "DATA_PATH=/tmp/notes.json" ];
          User = "65534:65534"; # nobody — nonroot
        };
      };
    in
    {
      packages.${system} = {
        quicknotes = quicknotes;
        default = quicknotes;
        docker = dockerImage;
      };

      # `nix develop` drops collaborators into a shell with the Go toolchain.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
