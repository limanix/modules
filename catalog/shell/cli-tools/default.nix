{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./help.nix ];

  programs.git.enable = true;

  # bat, and delta through it, highlight in the terminal's colors with the system flavor.
  environment.variables = lib.mkIf (config.lmx.capabilities.theme.flavor == "system") {
    BAT_THEME = lib.mkDefault "ansi";
  };

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
