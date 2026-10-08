{
  module,
  defaultConfiguration,
  evaluate,
  lib,
  pkgs,
  userName,
  verify,
  ...
}:
let
  shellOverride = evaluate [
    module.path
    { limanix.user.shell = pkgs.bashInteractive; }
  ];
  latte = evaluate [
    module.path
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
  inherit (latte.config.programs.starship) settings;
  preferencesOverride = evaluate [
    module.path
    {
      programs = {
        starship.settings = {
          palette = "custom";
          palettes.custom.blue = "#123456";
          directory.style = "bold cyan";
          hostname.ssh_only = true;
          status.disabled = true;
        };
        atuin.settings = {
          auto_sync = true;
          update_check = true;
        };
      };
    }
  ];
in
{
  evaluation = {
    shell = verify "suggested account shell and ordinary Bash override" (
      defaultConfiguration.config.limanix.user.shell == pkgs.zsh
      && shellOverride.config.limanix.user.shell == pkgs.bashInteractive
      && shellOverride.config.users.users.${userName}.shell == pkgs.bashInteractive
      && shellOverride.config.programs.zsh.enable
    ) shellOverride;
    preferences = verify "prompt and history preferences support ordinary overrides" (
      !defaultConfiguration.config.programs.starship.settings.hostname.ssh_only
      && defaultConfiguration.config.programs.starship.settings.palette == "catppuccin_mocha"
      && preferencesOverride.config.programs.starship.settings.palette == "custom"
      && preferencesOverride.config.programs.starship.settings.directory.style == "bold cyan"
      && !defaultConfiguration.config.programs.starship.settings.status.disabled
      && !defaultConfiguration.config.programs.atuin.settings.auto_sync
      && !defaultConfiguration.config.programs.atuin.settings.update_check
      && preferencesOverride.config.programs.starship.settings.hostname.ssh_only
      && preferencesOverride.config.programs.starship.settings.status.disabled
      && preferencesOverride.config.programs.atuin.settings.auto_sync
      && preferencesOverride.config.programs.atuin.settings.update_check
    ) preferencesOverride;
    theme = verify "the prompt follows the guest's flavor" (
      settings.palette == "catppuccin_latte"
      && settings.palettes.catppuccin_latte == latte.config.lmx.capabilities.theme.palette
    ) latte;
    segment = verify "outside tmux, the prompt shows the words of lmx status --short" (
      lib.hasPrefix ''[ -n "$TMUX" ] || '' settings.custom.lmx.command
      && lib.hasSuffix "lmx status --short" settings.custom.lmx.command
    ) latte;
  };
}
