{
  config,
  pkgs,
  profile,
  ...
}:
let
  python = pkgs.lib.last pkgs.posting.propagatedBuildInputs;
in
{
  theme = pkgs.runCommand "posting-theme" { } ''
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" XDG_DATA_HOME="$TMPDIR/data"
    export POSTING_THEME=${pkgs.lib.escapeShellArg config.environment.variables.POSTING_THEME}
    export PYTHONPATH="${pkgs.posting}/${python.sitePackages}:${python.pkgs.makePythonPath pkgs.posting.propagatedBuildInputs}"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/posting" "$XDG_DATA_HOME" collection
    ${profile}/bin/posting locate config > config.txt
    grep -F "$XDG_CONFIG_HOME/posting/config.yaml" config.txt
    ${python.interpreter} ${./theme-smoke.py}
    touch "$out"
  '';
}
