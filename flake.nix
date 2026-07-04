{
  description = "QuickNotes - reproducible Nix build of the DevOps-Intro Go service";

  # Channel pin; flake.lock freezes the exact nixpkgs revision so every clone
  # evaluates the same package set. nixos-25.11 is the newest stable channel
  # and ships go_1_26 = 1.26.4, the same toolchain the Lab 6 Dockerfile uses.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      # Linux only: aarch64 covers local nixos/nix container builds on the
      # Apple Silicon host, x86_64 covers CI runners. The OCI image target
      # is a Linux artifact, so darwin systems are deliberately left out.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
          (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        quicknotes = (pkgs.buildGoModule.override { go = pkgs.go_1_26; }) {
          pname = "quicknotes";
          version = "0.1.0";

          # Only app/ is a build input; nothing else in the repo can change
          # the output hash. Builds the server and the healthcheck probe.
          src = ./app;

          # QuickNotes has zero third-party dependencies. The first build
          # with a fake hash did not return a value to pin; it failed with
          # "vendor folder is empty, please set 'vendorHash = null;'".
          # null skips the vendor derivation entirely, there is nothing to
          # fetch, so nothing needs pinning.
          vendorHash = null;

          # Same knobs as the Lab 6 image build: no cgo so the binary is
          # static, symbols and DWARF stripped.
          env.CGO_ENABLED = "0";
          ldflags = [ "-s" "-w" ];
        };
        default = quicknotes;
      });

      # nix develop drops collaborators into a shell with the pinned
      # toolchain, no global installs needed.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go_1_26 pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
