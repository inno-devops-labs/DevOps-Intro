{
  description = "Lab 11 reproducible Go app and Docker image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      src = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter = path: type:
          let
            base = builtins.baseNameOf path;
          in
          !(base == "result" || pkgs.lib.hasPrefix "result-" base);
      };

      app = pkgs.buildGoModule {
        pname = "app";
        version = "1.0.0";

        inherit src;

        vendorHash = null;

        subPackages = [ "." ];

        ldflags = [ "-s" "-w" ];

        meta = with pkgs.lib; {
          description = "Simple reproducible Go app for Lab 11";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      rootfs = pkgs.buildEnv {
        name = "app-rootfs";
        paths = [ app ];
        pathsToLink = [ "/bin" ];
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "nix-app";
        tag = "1.0.0";
        contents = [ rootfs ];
        config = {
          Cmd = [ "/bin/app" ];
        };
      };
    in
    {
      packages.${system} = {
        default = app;
        app = app;
        dockerImage = dockerImage;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${app}/bin/app";
        };
      };
    };
}
