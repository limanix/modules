{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.lmx.capabilities.theme) flavor;
in
{
  imports = [ ./help.nix ];

  programs.git.enable = true;

  # bat, and delta through it, highlight in the terminal's colors with the system flavor.
  environment.variables.BAT_THEME = lib.mkDefault (
    if flavor == "system" then "ansi" else "Catppuccin ${lib.toSentenceCase flavor}"
  );

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
