{
  module,
  defaultConfiguration,
  evaluate,
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
  preferencesOverride = evaluate [
    module.path
    {
      programs = {
        starship.settings = {
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
      && !defaultConfiguration.config.programs.starship.settings.status.disabled
      && !defaultConfiguration.config.programs.atuin.settings.auto_sync
      && !defaultConfiguration.config.programs.atuin.settings.update_check
      && preferencesOverride.config.programs.starship.settings.hostname.ssh_only
      && preferencesOverride.config.programs.starship.settings.status.disabled
      && preferencesOverride.config.programs.atuin.settings.auto_sync
      && preferencesOverride.config.programs.atuin.settings.update_check
    ) preferencesOverride;
  };
}
