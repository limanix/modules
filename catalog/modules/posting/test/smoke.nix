{
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
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/posting" "$XDG_DATA_HOME"
    ${profile}/bin/posting locate config > config.txt
    grep -F "$XDG_CONFIG_HOME/posting/config.yaml" config.txt
    touch "$out"
  ''
