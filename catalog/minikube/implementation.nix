version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) pins;
  tools = import ./packages.nix {
    inherit version pinned pkgs;
  };

  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  priority = lib.meta.defaultPriority - builtins.length olderLines;

  versionedMinikube = pkgs.runCommandLocal "minikube-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.minikube}/bin/minikube" "$out/bin/minikube-${version}"
  '';
in
{
  lmx.pins = pins;
  lmx.internal.minikube.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.minikube)
    versionedMinikube
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Minikube ${tools.minikube.version} no longer receives upstream security updates.";
}
