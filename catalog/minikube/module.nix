version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.minikube.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedMinikube = pkgs.runCommand "minikube-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.minikube}/bin/minikube" "$out/bin/minikube-${version}"
  '';
in
{
  imports = [ ../k9s/default.nix ];

  environment.systemPackages = [
    (lib.setPrio priority tools.minikube)
    versionedMinikube
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Minikube ${tools.minikube.version} no longer receives upstream security updates.";
}
