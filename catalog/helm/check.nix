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
  warning = "Helm ${tools.helm.version} no longer receives upstream security updates.";
in
hasPackage tools.helm && (builtins.elem warning config.warnings == (tools.endOfLife == true))
