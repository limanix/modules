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

  versionedHelm = pkgs.runCommandLocal "helm-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.helm}/bin/helm" "$out/bin/helm-${version}"
  '';
in
{
  lmx.pins = pins;
  lmx.internal.helm.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.helm)
    versionedHelm
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Helm ${tools.helm.version} no longer receives upstream security updates.";
}
