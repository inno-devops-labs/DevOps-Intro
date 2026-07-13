{
  description = "Reproducible QuickNotes build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";

            src = ./app;

            subPackages = [ "." ];

            vendorHash = null;

            env = {
              CGO_ENABLED = "0";
            };

            ldflags = [
              "-s"
              "-w"
            ];

            postInstall = ''
              if [ ! -e "$out/bin/quicknotes" ]; then
                candidate="$(
                  find "$out/bin" \
                    -maxdepth 1 \
                    -type f \
                    -perm -0100 \
                    | head -n 1
                )"

                if [ -z "$candidate" ]; then
                  echo "QuickNotes executable was not found" >&2
                  exit 1
                fi

                mv "$candidate" "$out/bin/quicknotes"
              fi
            '';
          };

          docker = pkgs.dockerTools.buildLayeredImage {
            name = "quicknotes";
            tag = "lab11";
			
			contents = [ quicknotes ];

            created = "1970-01-01T00:00:01Z";

            extraCommands = ''
			  cp ${./app/seed.json} ./seed.json
			'';
			
			fakeRootCommands = ''
			  mkdir -p /data
			  chown 65532:65532 /data
			'';

		  enableFakechroot = true;

            config = {
              Entrypoint = [
                 "/bin/quicknotes"
              ];

              ExposedPorts = {
                "8080/tcp" = { };
              };

              User = "65532:65532";
              WorkingDir = "/";

            };
          };
        in
        {
          inherit quicknotes docker;

          default = quicknotes;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.go
              pkgs.gopls
              pkgs.golangci-lint
            ];

            CGO_ENABLED = 0;
          };
        }
      );
    };
}