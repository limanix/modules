{
  config,
  pkgs,
  configurations,
  ...
}:
let
  disabled = configurations.navigationDisabled;
  overridden = configurations.preferencesOverride;
in
{
  configuration =
    pkgs.runCommand "tmux-generated-configuration"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.tmux
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gawk
          pkgs.procps
          pkgs.findutils
        ];
        LMX_TMUX = "${pkgs.tmux}/bin/tmux";
        LMX_TMUX_ENABLED = config.environment.etc."tmux.conf".source;
        LMX_TMUX_DISABLED = disabled.config.environment.etc."tmux.conf".source;
        LMX_TMUX_OVERRIDDEN = overridden.config.environment.etc."tmux.conf".source;
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        export HOME="$TMPDIR/home"
        export TMUX_TMPDIR="$TMPDIR/tmux"
        export TERM=xterm-256color
        mkdir -p "$HOME" "$TMUX_TMPDIR"
        python ${./runtime-smoke.py}
        touch "$out"
      '';

  sessions =
    pkgs.runCommand "tmux-session-provider"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        LMX_SESSION_COMMAND = config.limanix.session.command;
        LMX_TMUX = "${pkgs.tmux}/bin/tmux";
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        export HOME="$TMPDIR/home"
        export TMUX_TMPDIR="$TMPDIR/tmux"
        export TERM=xterm-256color
        mkdir -p "$HOME" "$TMUX_TMPDIR"
        python ${./session-smoke.py}
        touch "$out"
      '';
}
