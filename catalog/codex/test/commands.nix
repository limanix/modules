{ pkgs, profile }:
pkgs.runCommand "codex-system-commands" { nativeBuildInputs = [ profile ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  codex --version > version.txt
  grep -F ${pkgs.lib.escapeShellArg pkgs.codex.version} version.txt
  codex exec --help > exec-help.txt
  grep -F 'Usage: codex exec' exec-help.txt
  codex login --help > login-help.txt
  grep -F -- '--device-auth' login-help.txt
  touch "$out"
''
