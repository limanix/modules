{
  config,
  pkgs,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Go ${tools.go.version} no longer receives upstream security updates.";
in
builtins.all hasPackage [
  tools.go
  config.lmx.capabilities.languageSupport.tools.gopls.package
  tools.delve
  pkgs.gcc
]
&&
  builtins.all
    (parser: builtins.elem parser config.lmx.capabilities.languageSupport.languages.go.parsers)
    [
      "go"
      "gomod"
      "gosum"
    ]
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
