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
    release: lib.versionOlder release.version tools.terraform.version
  ) releaseValues;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedTerraform = pkgs.runCommandLocal "terraform-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.terraform}/bin/terraform" "$out/bin/terraform-${version}"
  '';
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.terraform.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.terraform)
    versionedTerraform
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Terraform ${tools.terraform.version} no longer receives upstream security updates.";
}
