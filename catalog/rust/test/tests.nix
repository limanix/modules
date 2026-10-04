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
  expected = tools.rust-analyzer;
  declaration = (capability allConfiguration).tools.rust-analyzer;
  replacement = (toolsFor (builtins.head variants).version).rust-analyzer;
  providerOverrideFor =
    paths: package:
    evaluate (
      paths
      ++ [
        {
          lmx.capabilities.languageSupport.tools.rust-analyzer = {
            inherit package;
            command = "${package}/bin/rust-analyzer";
            args = [ "--version" ];
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
        "rustc"
        "cargo"
        "rustfmt"
        "clippy"
        "rust-analyzer"
      ]
      && declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allConfiguration declaration.package
      && declaration.command == "${expected}/bin/rust-analyzer"
      && selectedPackage allConfiguration expected
      && !allConfiguration.config.programs.neovim.enable
    ) allConfiguration;
    userOverride = verify "the selected replacement provider is installed in the system profile" (
      selectedPackage providerOverride replacement && installedAsDeclared providerOverride replacement
    ) providerOverride;
  };
}
