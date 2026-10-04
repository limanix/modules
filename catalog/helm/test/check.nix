{
  config,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Helm ${tools.helm.version} no longer receives upstream security updates.";
in
hasPackage tools.helm && (builtins.elem warning config.warnings == (tools.endOfLife == true))
