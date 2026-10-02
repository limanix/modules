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
&& hasPackage config.lmx.capabilities.languageSupport.tools.pyright.package
&& builtins.elem "python" config.lmx.capabilities.languageSupport.languages.python.parsers
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
