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
  warning = "Node.js ${tools.nodejs.version} no longer receives upstream security updates.";
in
hasPackage tools.nodejs
&& builtins.elem "javascript" config.lmx.capabilities.languageSupport.languages.javascript.parsers
&&
  builtins.all
    (parser: builtins.elem parser config.lmx.capabilities.languageSupport.languages.typescript.parsers)
    [
      "typescript"
      "tsx"
    ]
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
