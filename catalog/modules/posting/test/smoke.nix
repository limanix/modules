{
  config,
  pkgs,
  profile,
}:
pkgs.runCommand "posting-installed-command"
  {
    nativeBuildInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
  }
  ''
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" XDG_DATA_HOME="$TMPDIR/data"
    export POSTING_THEME=${pkgs.lib.escapeShellArg config.environment.variables.POSTING_THEME}
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/posting" "$XDG_DATA_HOME"
    ${profile}/bin/posting locate config > config.txt
    grep -F "$XDG_CONFIG_HOME/posting/config.yaml" config.txt
    # Posting keeps Textual's own themes, the terminal theme among them.
    ${pkgs.python3.withPackages (packages: [ packages.textual ])}/bin/python -c \
      'import os, textual.theme; assert os.environ["POSTING_THEME"] in textual.theme.BUILTIN_THEMES'
    touch "$out"
  ''
