{
  config,
  pkgs,
  version,
  hasPackage,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  warning = "Terraform ${tools.terraform.version} no longer receives upstream security updates.";
in
hasPackage tools.terraform && (builtins.elem warning config.warnings == (tools.endOfLife == true))
