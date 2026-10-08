{ pkgs, lib, ... }:
{
  imports = [
    ../git/default.nix
    ./help.nix
  ];

  environment.systemPackages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.bat
    pkgs.eza
    pkgs.delta
    pkgs.jq
    pkgs.yq-go
    pkgs.xh
    pkgs.btop
    pkgs.dust
    pkgs.duf
    pkgs.tealdeer
  ];

  programs.git.config = {
    core.pager = lib.mkDefault "${pkgs.delta}/bin/delta";
    interactive.diffFilter = lib.mkDefault "${pkgs.delta}/bin/delta --color-only";
  };
}
