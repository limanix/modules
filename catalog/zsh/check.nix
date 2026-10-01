{
  config,
  pkgs,
  hasPackage,
  ...
}:
config.limanix.user.shell == pkgs.zsh
&& config.users.users.${config.limanix.user.name}.shell == config.limanix.user.shell
&& config.programs.zsh.enable
&& config.programs.zsh.enableCompletion
&& config.programs.zsh.autosuggestions.enable
&& config.programs.zsh.syntaxHighlighting.enable
&& config.programs.fzf.keybindings
&& config.programs.starship.enable
&& config.programs.atuin.enable
&& config.programs.atuin.enableZshIntegration
&& !config.programs.atuin.settings.auto_sync
&& !config.programs.atuin.settings.update_check
&& config.programs.zoxide.enable
&& config.programs.direnv.enable
&& config.programs.direnv.nix-direnv.enable
&& builtins.all hasPackage [
  pkgs.carapace
  pkgs.fzf
  pkgs.zsh-fzf-tab
]
