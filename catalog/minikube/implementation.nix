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
    release: lib.versionOlder release.version tools.minikube.version
  ) releaseValues;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedMinikube = pkgs.runCommandLocal "minikube-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.minikube}/bin/minikube" "$out/bin/minikube-${version}"
  '';
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.minikube.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.minikube)
    versionedMinikube
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Minikube ${tools.minikube.version} no longer receives upstream security updates.";
}
