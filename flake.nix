{
  description = "QuickNotes — reproducible builds via Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;

            # No external Go dependencies — stdlib only.
            vendorHash = null;

            # CGO must be in `env` in nixpkgs ≥ 25.11 (top-level CGO_ENABLED conflicts).
            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];

            # Tests require a writable data dir; skip in sandbox.
            doCheck = false;
          };
        in
        {
          inherit quicknotes;
          default = quicknotes;

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "nix";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ quicknotes ];
              pathsToLink = [ "/bin" ];
            };

            config = {
              # Exec-form entrypoint — no shell needed.
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = {}; };
              # Nonroot UID 65532 — mirrors Lab 6 distroless:nonroot discipline.
              User = "65532:65532";
            };
          };
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls golangci-lint ];
          };
        }
      );
    };
}
