{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "lab11-app";
  version = "1.0.0";

  src = ./.;

  # Stdlib only — no modules to vendor (see `go.mod`).
  vendorHash = null;

  installPhase = ''
    mkdir -p $out/bin
    cp $GOPATH/bin/lab11-app $out/bin/ || cp ./lab11-app $out/bin/
    ln -sf lab11-app $out/bin/app
    mkdir -p $out/share/lab11-app
    cp index.html $out/share/lab11-app/
  '';

  meta = with pkgs.lib; {
    description = "DevOps Introduction Lab 11 Application";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}