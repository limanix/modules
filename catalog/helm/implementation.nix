version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  releases = import ./releases.nix;
  source = releases.sources.${releases.versions.${version}.source};
  tools = import ./packages.nix {
    inherit version pinned;
  };

  releaseValues = builtins.attrValues releases.versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.helm.version
  ) releaseValues;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedHelm = pkgs.runCommandLocal "helm-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.helm}/bin/helm" "$out/bin/helm-${version}"
  '';
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.helm.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.helm)
    versionedHelm
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Helm ${tools.helm.version} no longer receives upstream security updates.";
}
