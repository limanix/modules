{
  config,
  pkgs,
  lib,
  ...
}:
let
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
    [[ $LMX_PERSONAL == yes ]]
    [[ ''${+functions[_carapace_completer]} == 1 ]]
    [[ ''${+functions[_zsh_highlight]} == 1 ]]
    [[ ''${+functions[_zsh_autosuggest_start]} == 1 ]]
    [[ ''${+functions[__zoxide_z]} == 1 ]]
    [[ ''${+functions[_direnv_hook]} == 1 ]]
    zle -l | grep -F fzf-tab-complete
    zle -l | grep -F fzf-file-widget
    bindkey '^R' | grep -F atuin
    bindkey '^T' | grep -F fzf-file-widget
    [[ $STARSHIP_CONFIG == /nix/store/* ]]
    starship print-config | grep -F 'ssh_only = false'
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
          config.system.path
          pkgs.python3
          pkgs.proot
          pkgs.gnugrep
        ];
        LMX_ZSH = "${pkgs.zsh}/bin/zsh";
        LMX_ETC = etc;
        LMX_PROFILE = config.system.path;
        LMX_CHECK = check;
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        export HOME="$TMPDIR/home" TERM=xterm-256color
        export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
        printf 'LMX_PERSONAL=yes\n' > "$HOME/.zshrc"
        python ${./startup-smoke.py}
        touch "$out"
      '';
}
