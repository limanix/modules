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
  warning = "K9s ${tools.k9s.version} no longer receives upstream security updates.";
  warnings = builtins.filter (message: message == warning) config.warnings;
in
hasPackage tools.k9s && builtins.length warnings == (if tools.endOfLife == true then 1 else 0)
