{
  pkgs,
  profile,
  version,
}:
pkgs.runCommand "claude-system-commands" { nativeBuildInputs = [ profile ]; } ''
  export HOME="$TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  claude --version > version.txt
  grep -F -- ${pkgs.lib.escapeShellArg version} version.txt
  claude --help > help.txt
  grep -F -- '--help' help.txt
  touch "$out"
''
