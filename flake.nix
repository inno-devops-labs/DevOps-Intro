{
  description = "QuickNotes — reproducible build via Nix flake (Lab 11)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";

        src = ./app;

        # No external Go dependencies (go.mod has no `require` block),
        # so there is no vendor tree to hash.
        vendorHash = null;

        env.CGO_ENABLED = 0;
        ldflags = [ "-s" "-w" ];

        # Only build the top-level `quicknotes` binary; skip cmd/healthcheck
        # (Lab 6 runtime concern, not needed for the Nix reproducibility proof).
        subPackages = [ "." ];

        doCheck = false;

        meta = {
          description = "QuickNotes HTTP service";
          mainProgram = "quicknotes";
        };
      };

      # dockerTools.buildImage is deterministic when `created = "now"` is
      # NOT set. Omitting `created` pins it to the epoch, so the image
      # tarball digest is a pure function of its contents.
      dockerImage = pkgs.dockerTools.buildImage {
        name = "quicknotes";
        tag = "nix";

        # Bring the nonroot user + /etc/passwd so the process has a UID
        # to run as (distroless-style, no shell). Also stage a writable
        # /data dir owned by uid 65532, mirroring Lab 6's Dockerfile.
        copyToRoot = pkgs.buildEnv {
          name = "quicknotes-root";
          paths = [
            quicknotes
            pkgs.dockerTools.caCertificates
            (pkgs.runCommand "nonroot-user" { } ''
              mkdir -p $out/etc
              echo 'nonroot:x:65532:65532:nonroot:/:/sbin/nologin' > $out/etc/passwd
              echo 'nonroot:x:65532:' > $out/etc/group
            '')
          ];
          pathsToLink = [ "/bin" "/etc" ];
        };

        # dockerTools.buildImage's extraCommands runs unprivileged in a
        # sandbox, so `chown 65532` fails. Making /data mode 1777 is safe
        # here — the container process runs as uid 65532 and needs to
        # write notes.json under this path.
        extraCommands = ''
          mkdir -p data
          chmod 1777 data
        '';

        config = {
          Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = { }; };
          User = "65532:65532";
          WorkingDir = "/";
          Env = [
            "ADDR=:8080"
            "DATA_PATH=/data/notes.json"
            "SEED_PATH=${quicknotes.src}/seed.json"
          ];
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
        packages = with pkgs; [
          go
          gopls
          golangci-lint
        ];
      };
    };
}
