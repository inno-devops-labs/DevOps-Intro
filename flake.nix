{
  description = "QuickNotes Reproducible Build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in {
      packages = forAllSystems (system: 
        let
          pkgs = pkgsFor system;
          
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "1.0.0";
            src = ./app;
            
            env = {
                CGO_ENABLED = "0";
            };  
            vendorHash = null;
            
            ldflags = [ "-s" "-w" ];
          };

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes-image";
            tag = "latest";
            copyToRoot = [ quicknotes ];
            
            config = {
              Entrypoint = [ "${quicknotes}/bin/quicknotes" ]; 
              ExposedPorts = {
                "8080/tcp" = {};
              };
              # 4. Запуск от nonroot пользователя
              User = "65532:65532";
            };
          };
        in {
          inherit quicknotes docker;
          default = quicknotes;
        }
      );

      devShells = forAllSystems (system: 
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls golangci-lint ];
          };
        }
      );
    };
}