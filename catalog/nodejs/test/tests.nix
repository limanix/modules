{
  variants,
  allConfiguration,
  evaluate,
  pkgs,
  lib,
  capability,
  installedAsDeclared,
  selectedPackage,
  packagePriority,
  coexistence,
  verify,
  ...
}:
let
  expected = pkgs.typescript-language-server;
  declaration = (capability allConfiguration).tools.typescript-language-server;
  replacement = pkgs.writeShellScriptBin "typescript-language-server" ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${expected}/bin/typescript-language-server "$@"
  '';
  providerModule = {
    lmx.capabilities.languageSupport.tools.typescript-language-server = {
      package = replacement;
      command = "${replacement}/bin/typescript-language-server";
      args = [
        "--catalog-smoke"
        "--stdio"
      ];
    };
  };
  providerOverride = evaluate ((map (variant: variant.path) variants) ++ [ providerModule ]);
in
{
  configurations = {
    userOverride = providerOverride;
  };
  evaluation = {
    allLines = verify "the final language server declaration and profile agree" (
      coexistence [ "nodejs" ]
      && declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allConfiguration declaration.package
      && declaration.command == "${expected}/bin/typescript-language-server"
      && declaration.args == [ "--stdio" ]
      &&
        declaration.languages == [
          "javascript"
          "typescript"
        ]
      && selectedPackage allConfiguration expected
      && !allConfiguration.config.programs.neovim.enable
    ) allConfiguration;
    userOverride = verify "the selected replacement provider is installed in the system profile" (
      selectedPackage providerOverride replacement && installedAsDeclared providerOverride replacement
    ) providerOverride;
  };
}
