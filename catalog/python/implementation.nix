version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.python.version
  ) releases;
  rank = builtins.length olderReleases;
  priority = lib.meta.defaultPriority - rank;
  runtimePython = import ./runtime-package.nix {
    inherit lib;
    python = lib.setPrio priority tools.python;
  };

  versionedPython = pkgs.runCommand "python-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.python.interpreter}" "$out/bin/python-${version}"
  '';
in
{
  lmx.capabilities.languageSupport = {
    languages.python.parsers = [ "python" ];
    tools.pyright = lib.mkOverride (1000 - rank) {
      package = lib.setPrio priority pkgs.pyright;
      command = "${pkgs.pyright}/bin/pyright-langserver";
      args = [ "--stdio" ];
      languages = [ "python" ];
    };
  };

  environment.systemPackages = [
    runtimePython
    (lib.setPrio priority tools.virtualenv)
    versionedPython
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Python ${tools.python.version} no longer receives upstream security updates.";
}
