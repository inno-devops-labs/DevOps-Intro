{
  description = "QuickNotes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "1.0.0";

          src = ./app;
          vendorHash = null; # vendorHash is null since quicknotes does not depend on external libraries
          env = {
            CGO_ENABLED = 0;
          };
          ldflags = [ "-s" "-w" ];
        };

        dockerImage = pkgs.dockerTools.buildImage {
          name = "quicknotes-oci";
          tag = "latest";
          
          created = 
            let
              envEpoch = builtins.getEnv "SOURCE_DATE_EPOCH";
            in 
              if envEpoch != "" then envEpoch else "1970-01-01T00:00:01Z"; 

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes pkgs.cacert ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
            User = "10001:10001";
          };
        };
      in
      {
        packages = {
          inherit quicknotes;
          docker = dockerImage;
          default = quicknotes;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            golangci-lint
          ];
        };
      }
    );
}