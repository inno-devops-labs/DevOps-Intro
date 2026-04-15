{ pkgs ? import <nixpkgs> { } }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";

  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      type == "directory"
      || builtins.elem (baseNameOf path) [
        "go.mod"
        "main.go"
      ];
  };
  vendorHash = null;

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-buildid="
  ];

  postInstall = ''
    mv "$out/bin/nix-repro-app" "$out/bin/app"
  '';
}
