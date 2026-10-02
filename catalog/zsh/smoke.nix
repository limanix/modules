{
  config,
  pkgs,
  profile,
  lib,
  ...
}:
let
  # Login startup rebuilds PATH from /run/current-system/sw. Add the base
  # commands used by global shell setup and assertions to the catalog profile.
  startupProfile = pkgs.buildEnv {
    name = "zsh-startup-profile";
    paths = [
      profile
      pkgs.coreutils
      pkgs.gnugrep
    ];
  };
  etc = pkgs.runCommand "zsh-smoke-etc" { } (
    "mkdir -p $out\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (name: entry: ''
          mkdir -p "$out/$(dirname ${lib.escapeShellArg name})"
          ln -s ${entry.source} "$out/${name}"
        '')
        (
          lib.filterAttrs (
            name: _:
            builtins.elem name [
              "zshenv"
              "zshrc"
              "zprofile"
              "zinputrc"
              "atuin/config.toml"
            ]
          ) config.environment.etc
        )
    )
  );
  check = pkgs.writeText "zsh-startup-check.zsh" ''
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
  '';
in
{
  startup =
    pkgs.runCommand "zsh-startup-smoke"
      {
        nativeBuildInputs = [
          startupProfile
          pkgs.python3
          pkgs.proot
        ];
        LMX_ZSH = "${pkgs.zsh}/bin/zsh";
        LMX_ETC = etc;
        LMX_PROFILE = startupProfile;
        LMX_CHECK = check;
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        export HOME="$TMPDIR/home" TERM=xterm-256color
        export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
        python ${./startup-smoke.py}
        touch "$out"
      '';
}
