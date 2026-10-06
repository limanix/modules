{
  config,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Task ${tools.task.version} no longer receives upstream security updates.";
in
hasPackage tools.task && (builtins.elem warning config.warnings == (tools.endOfLife == true))
