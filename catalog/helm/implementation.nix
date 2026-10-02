version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.helm.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedHelm = pkgs.runCommand "helm-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.helm}/bin/helm" "$out/bin/helm-${version}"
  '';
in
{
  environment.systemPackages = [
    (lib.setPrio priority tools.helm)
    versionedHelm
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Helm ${tools.helm.version} no longer receives upstream security updates.";
}
