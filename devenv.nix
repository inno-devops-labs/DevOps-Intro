{ pkgs, ... }:

{
  packages = with pkgs; [
    git
    openssh
    python3
    curl
    jq
    gh
  ];

  languages.go.enable = true;

  enterShell = ''
    echo "── DevOps-Intro devenv ──"
    go version
    git --version
    echo "QuickNotes: cd app && go run ."
  '';
}
