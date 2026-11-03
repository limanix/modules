{ pkgs, ... }:
{
  imports = [
    ./help.nix
    ./theme.nix
  ];

  programs.git.enable = true;

  environment.systemPackages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.bat
    pkgs.eza
    pkgs.jq
    pkgs.yq-go
    pkgs.xh
    pkgs.dust
    pkgs.duf
    pkgs.tealdeer
  ];
}
