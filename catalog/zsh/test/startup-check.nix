{ config, pkgs }:
pkgs.writeText "zsh-startup-check.zsh" ''
  setopt ERR_EXIT
  TRAPZERR() { print -u2 "Zsh startup assertion failed at $funcfiletrace[1]"; }
  if [[ $LMX_EXPECT_PERSONAL == yes ]]; then
    [[ $LMX_PERSONAL == yes ]]
    [[ $(zsh-newuser-install) == LMX_PERSONAL_NEWUSER ]]
  else
    [[ -z ''${LMX_PERSONAL:-} ]]
    [[ ''${+functions[zsh-newuser-install]} == 0 ]]
    autoload -U +X zsh-newuser-install
    [[ ''${+functions[zsh-newuser-install]} == 1 ]]
  fi
  [[ $ZSH == ${config.programs.zsh.ohMyZsh.package}/share/oh-my-zsh ]]
  [[ ''${+functions[omz]} == 1 ]]
  [[ ''${+functions[_carapace_completer]} == 1 ]]
  [[ ''${+functions[_zsh_highlight]} == 1 ]]
  [[ ''${+functions[_zsh_autosuggest_start]} == 1 ]]
  [[ ''${+functions[__zoxide_z]} == 1 ]]
  [[ ''${+functions[_direnv_hook]} == 1 ]]
  # The -i -c probe has no prompt; run the first-prompt widget binding explicitly.
  _zsh_autosuggest_start
  bindkey '^I' | grep -F fzf-tab-complete
  [[ $widgets[.fzf-tab-orig-expand-or-complete] == completion:* ]]
  zstyle -s ':completion:complete:cd:argument-rest:local-directories' menu menu_style
  [[ $menu_style == no ]]
  zle -l | grep -F fzf-tab-complete
  zle -l | grep -F fzf-file-widget
  bindkey '^R' | grep -F atuin
  bindkey '^T' | grep -F fzf-file-widget
  [[ $STARSHIP_CONFIG == /nix/store/* ]]
  starship print-config | grep -F 'ssh_only = false'
  starship print-config | grep -F 'palette = "catppuccin_mocha"'
  starship module directory | grep -F '38;2;137;180;250'
  [[ -n $(starship module hostname) ]]
  starship module status --status 7 | grep -F 7
  [[ -z $(starship module status --status 0) ]]
  grep -F 'auto_sync = false' /etc/atuin/config.toml
  grep -F 'update_check = false' /etc/atuin/config.toml
  print LMX_ZSH_STARTUP_OK
''
