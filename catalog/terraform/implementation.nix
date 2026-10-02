version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.terraform.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedTerraform = pkgs.runCommand "terraform-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.terraform}/bin/terraform" "$out/bin/terraform-${version}"
  '';
in
{
  environment.systemPackages = [
    (lib.setPrio priority tools.terraform)
    versionedTerraform
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Terraform ${tools.terraform.version} no longer receives upstream security updates.";
}
