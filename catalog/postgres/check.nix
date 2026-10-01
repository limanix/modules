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
  warning = "PostgreSQL ${tools.postgres.version} no longer receives upstream security updates.";
in
hasPackage tools.postgres
&& builtins.elem "/share/postgresql" config.environment.pathsToLink
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
