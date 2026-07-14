{
  description = "Reproducible Nix build for QuickNotes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";

        src = ./app;

        vendorHash = "sha256-6nOwg48X8bfUliKtHbMMVOoi4aZ3coyYClMWGiYPrYc=";

        # QuickNotes has no external Go modules. This deterministic marker
        # allows the exercise to demonstrate a non-null vendor hash.
        overrideModAttrs = _final: _previous: {
          postBuild = ''
            printf '%s\n' \
              "QuickNotes has no external Go modules." \
              > vendor/NO_EXTERNAL_DEPENDENCIES
          '';
        };

        env.CGO_ENABLED = "0";

        ldflags = [
          "-s"
          "-w"
        ];
      };

      docker = pkgs.dockerTools.buildImage {
        name = "quicknotes";
        tag = "lab11";

        copyToRoot = quicknotes;

        extraCommands = ''
          mkdir -p etc app tmp

          printf '%s\n' \
            'root:x:0:0:root:/root:/sbin/nologin' \
            'nonroot:x:65532:65532:nonroot:/nonexistent:/sbin/nologin' \
            > etc/passwd

          printf '%s\n' \
            'root:x:0:' \
            'nonroot:x:65532:' \
            > etc/group

          cp ${./app/seed.json} app/seed.json
          chmod 1777 tmp
        '';

        created = "1970-01-01T00:00:01Z";

        config = {
          Entrypoint = [ "/bin/quicknotes" ];
          ExposedPorts = {
            "8080/tcp" = { };
          };
          User = "nonroot:nonroot";
          WorkingDir = "/app";
          Env = [
            "ADDR=:8080"
            "DATA_PATH=/tmp/quicknotes/notes.json"
            "SEED_PATH=/app/seed.json"
          ];
        };
      };
    in
    {
      packages.${system} = {
        inherit quicknotes docker;
        default = quicknotes;
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
