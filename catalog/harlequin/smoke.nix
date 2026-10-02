{ pkgs, profile, ... }:
let
  package = import ./package.nix { inherit pkgs; };
  python = pkgs.lib.last package.propagatedBuildInputs;
in
{
  adapters = pkgs.runCommand "harlequin-installed-adapters" { } ''
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" NO_COLOR=1
    mkdir -p "$HOME" "$XDG_CONFIG_HOME"
    ${profile}/bin/harlequin --version > version.txt
    grep -F 'postgres, version' version.txt
    ${profile}/bin/harlequin --help > help.txt
    grep -F 'postgres Adapter Options' help.txt
    touch "$out"
  '';
  theme = pkgs.runCommand "harlequin-theme" { } ''
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config"
    export PYTHONPATH="${package}/${python.sitePackages}:${python.pkgs.makePythonPath package.propagatedBuildInputs}"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/harlequin"
    ${python.interpreter} ${./theme-smoke.py}
    touch "$out"
  '';
}
