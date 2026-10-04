{
  config,
  tools,
  hasPackage,
  ...
}:
let
  warning = "PostgreSQL ${tools.postgres.version} no longer receives upstream security updates.";
in
hasPackage tools.postgres
&& hasPackage tools.pgConfig
&& builtins.elem "/share/postgresql" config.environment.pathsToLink
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
