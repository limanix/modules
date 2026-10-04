{
  config,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Minikube ${tools.minikube.version} no longer receives upstream security updates.";
in
hasPackage tools.minikube && (builtins.elem warning config.warnings == (tools.endOfLife == true))
