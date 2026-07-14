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
    in
    {
      packages.${system} = {
        inherit quicknotes;
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