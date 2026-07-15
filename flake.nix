{
  description = "QuickNotes - reproducible build with Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;
          vendorHash = null;
          subPackages = [ "." ];
          ldflags = [ "-s" "-w" ];
        };
        
        dockerImage = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "latest";
          config = {
            Cmd = [ "${self.packages.${system}.quicknotes}/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
            User = "nonroot:nonroot";
          };
        };
        
        default = self.packages.${system}.quicknotes;
      };
      
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
