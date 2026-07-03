{
  description = "Reproducible QuickNotes build (Lab 11)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = false;
          };

          # buildGo124Module: nixos-25.11 ships Go 1.24, matching app/go.mod.
          # QuickNotes is stdlib-only (no go.sum) — vendorHash pins the (empty) module download.
          quicknotes = pkgs.buildGo124Module {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;

            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];

            postInstall = ''
              mkdir -p $out/share/quicknotes
              cp ${./app}/seed.json $out/share/quicknotes/seed.json
            '';
          };

          quicknotesImageRoot = pkgs.runCommand "quicknotes-image-root" { } ''
            mkdir -p $out/bin $out/data
            cp ${quicknotes}/bin/quicknotes $out/bin/quicknotes
            cp ${./app}/seed.json $out/data/seed.json
            chmod 755 $out/bin/quicknotes
            # Writable by nonroot (65532) inside the OCI image — chown needs fakeroot in CI.
            chmod -R a+rwx $out/data
          '';

          # Image `created` follows SOURCE_DATE_EPOCH so CI can prove the compare gate
          # (workflow sets "0" in both jobs for green; "1" vs "0" in A/B for red demo).
          created =
            let
              epochStr = builtins.getEnv "SOURCE_DATE_EPOCH";
            in
              if epochStr == "0" then "1970-01-01T00:00:00Z"
              else if epochStr == "1" then "1970-01-01T00:00:01Z"
              else "1970-01-01T00:00:01Z"; # local / unset — matches first reproducible baseline

          dockerImage = pkgs.dockerTools.buildImage {
            name = "quicknotes-nix";
            tag = "0.1.0";
            copyToRoot = quicknotesImageRoot;
            config = {
              User = "65532:65532";
              ExposedPorts = {
                "8080/tcp" = { };
              };
              Entrypoint = [ "/bin/quicknotes" ];
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/data/seed.json"
              ];
            };
            inherit created;
          };
        in {
          default = quicknotes;
          inherit quicknotes;
          docker = dockerImage;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = false;
          };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go_1_24
              gopls
              golangci-lint
            ];
          };
        });
    };
}
