{
  description = "QuickNotes — reproducible build via Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;
          vendorHash = null;
          env.CGO_ENABLED = 0;
          ldflags = [ "-s" "-w" ];
          meta = {
            description = "QuickNotes — a small Go JSON notes API";
            mainProgram = "quicknotes";
          };
        };

        # buildLayeredImage + fakeRootCommands (not buildImage + runAsRoot)
        # deliberately: runAsRoot spins up a real QEMU/KVM VM to get
        # genuine root, which fails wherever nested virtualization isn't
        # available (e.g. inside a plain Docker container, used here as
        # the second independent build environment). fakeRootCommands
        # achieves the same chown via a lightweight fakeroot/fakechroot
        # shim instead, with no VM required.
        dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "quicknotes";
          tag = "nix";
          contents = [ quicknotes ];

          fakeRootCommands = ''
            mkdir -p /data
            chown 65532:65532 /data
          '';
          enableFakechroot = true;

          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = { "8080/tcp" = { }; };
            User = "65532:65532";
            WorkingDir = "/";
          };
        };
      in
      {
        packages = {
          default = quicknotes;
          quicknotes = quicknotes;
          docker = dockerImage;
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
}
