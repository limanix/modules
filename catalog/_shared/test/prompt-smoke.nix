# Starts an interactive shell that sources a prompt's initialization, then runs a check script in
# the same shell: Zsh without startup files, or Bash without them.
{
  pkgs,
  name,
  shell,
  init,
  check,
  path ? [ ],
}:
let
  command =
    {
      zsh = [
        "${pkgs.zsh}/bin/zsh"
        "-f"
        "-i"
        "-c"
      ];
      bash = [
        "${pkgs.bashInteractive}/bin/bash"
        "--norc"
        "--noprofile"
        "-i"
        "-c"
      ];
    }
    .${shell};
in
pkgs.runCommand "prompt-smoke-${name}-${shell}"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.git
    ]
    ++ path;
    PYTHONPATH = ./.;
    LMX_SHELL = builtins.toJSON command;
    LMX_INIT = pkgs.writeText "prompt-init-${name}-${shell}" init;
    LMX_CHECK = pkgs.writeText "prompt-check-${name}-${shell}" check;
    TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
  }
  ''
    export HOME="$TMPDIR/home" TERM=xterm-256color
    mkdir -p "$HOME"
    python ${./prompt-smoke.py}
    touch "$out"
  ''
