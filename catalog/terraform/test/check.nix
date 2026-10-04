{
  config,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Terraform ${tools.terraform.version} no longer receives upstream security updates.";
in
hasPackage tools.terraform && (builtins.elem warning config.warnings == (tools.endOfLife == true))
