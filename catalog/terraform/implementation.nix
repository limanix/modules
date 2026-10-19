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

  # Lines rank by their numbers: lines from the base or unstable record no exact version.
  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  priority = lib.meta.defaultPriority - builtins.length olderLines;

  versionedTerraform = pkgs.runCommandLocal "terraform-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.terraform}/bin/terraform" "$out/bin/terraform-${version}"
  '';
in
{
  lmx.pins = pins;
  lmx.internal.terraform.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.terraform)
    versionedTerraform
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Terraform ${tools.terraform.version} no longer receives upstream security updates.";
}
