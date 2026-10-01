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
  warning = "Go ${tools.go.version} no longer receives upstream security updates.";
in
builtins.all hasPackage [
  tools.go
  config.lmx.capabilities.editor.tools.gopls.package
  tools.delve
  pkgs.gcc
]
&& builtins.all (parser: builtins.elem parser config.lmx.capabilities.editor.languages.go.parsers) [
  "go"
  "gomod"
  "gosum"
]
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
