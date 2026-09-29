version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.k9s.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedK9s = pkgs.runCommand "k9s-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.k9s}/bin/k9s" "$out/bin/k9s-${version}"
  '';
in
{
  environment.systemPackages = [
    (lib.setPrio priority tools.k9s)
    versionedK9s
  ];
}
