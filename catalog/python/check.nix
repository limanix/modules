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
  warning = "Python ${tools.python.version} no longer receives upstream security updates.";
in
hasPackage tools.python
&& hasPackage tools.virtualenv
&& builtins.elem "python" config.lmx.capabilities.editor.languages.python.parsers
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
