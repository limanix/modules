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
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedPython = pkgs.runCommand "python-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.python.interpreter}" "$out/bin/python-${version}"
  '';
in
{
  environment.systemPackages =
    map (lib.setPrio priority) [
      tools.python
      tools.virtualenv
    ]
    ++ [ versionedPython ];

  warnings = lib.optional tools.endOfLife "Python ${tools.python.version} no longer receives upstream security updates.";
}
