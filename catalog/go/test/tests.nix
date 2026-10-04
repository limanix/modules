{
  variants,
  allConfiguration,
  evaluate,
  lib,
  capability,
  toolsFor,
  installedAsDeclared,
  selectedPackage,
  packagePriority,
  coexistence,
  verify,
  ...
}:
let
  newest = lib.last variants;
  tools = toolsFor newest.version;
  expected = tools.gopls;
  declaration = (capability allConfiguration).tools.gopls;
  replacement = (toolsFor (builtins.head variants).version).gopls;
  providerOverrideFor =
    paths: package:
    evaluate (
      paths
      ++ [
        {
          lmx.capabilities.languageSupport.tools.gopls = {
            inherit package;
            command = "${package}/bin/gopls";
            args = [ "version" ];
          };
        }
      ]
    );
  providerOverride = providerOverrideFor (map (variant: variant.path) variants) replacement;
in
{
  configurations = {
    userOverride = providerOverride;
  };
  evaluation = {
    allLines = verify "declaration and profile package select the same newest provider" (
      coexistence [
        "go"
        "gopls"
        "delve"
      ]
      && declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allConfiguration declaration.package
      && declaration.command == "${expected}/bin/gopls"
      && declaration.languages == [ "go" ]
      && selectedPackage allConfiguration expected
      && !allConfiguration.config.programs.neovim.enable
    ) allConfiguration;
    userOverride = verify "the selected replacement provider is installed in the system profile" (
      selectedPackage providerOverride replacement && installedAsDeclared providerOverride replacement
    ) providerOverride;
  };
}
