{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  cfg = configuration.config;
in
{
  eval = {
    components =
      cfg.programs.zsh.enable
      && cfg.programs.tmux.enable
      && cfg.programs.neovim.enable
      && cfg.programs.lazygit.enable
      && cfg.programs.git.enable
      && cfg.programs.yazi.enable
      && helpers.installed configuration pkgs.gh
      && helpers.installed configuration pkgs.ripgrep
      && cfg.limanix.session.command != null;
    noDocker = !cfg.virtualisation.docker.enable;
  };
}
