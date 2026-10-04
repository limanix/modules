{ pkgs, profile }:
pkgs.runCommand "lazygit-installed-commands" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
  export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" XDG_STATE_HOME="$TMPDIR/state"
  mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"
  ${profile}/bin/lazygit --version
  ${profile}/bin/git --version
  touch "$out"
''
