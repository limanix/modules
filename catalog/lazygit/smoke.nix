{ config, pkgs, ... }:
{
  theme =
    pkgs.runCommand "lazygit-theme-smoke"
      {
        nativeBuildInputs = [
          pkgs.python3
          config.programs.git.package
        ];
        LMX_LAZYGIT = "${config.programs.lazygit.package}/bin/lazygit";
        LMX_CONFIG = config.environment.etc."xdg/lazygit/config.yml".source;
      }
      ''
        export HOME="$TMPDIR/home" TERM=xterm-256color COLORTERM=truecolor
        export XDG_CONFIG_HOME="$HOME/.config" XDG_CONFIG_DIRS="$TMPDIR/system"
        export XDG_STATE_HOME="$HOME/.local/state"
        mkdir -p "$XDG_CONFIG_DIRS/lazygit" "$XDG_CONFIG_HOME/lazygit" "$XDG_STATE_HOME"
        cp "$LMX_CONFIG" "$XDG_CONFIG_DIRS/lazygit/config.yml"
        git init project
        cd project
        python ${./theme-smoke.py}
        touch "$out"
      '';
}
