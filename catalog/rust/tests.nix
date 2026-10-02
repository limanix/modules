{
  variants,
  allVersionsConfiguration,
  reversedVersionsConfiguration,
  defaultConfiguration,
  evaluate,
  pkgs,
  lib,
  capability,
  toolsFor,
  installedAsDeclared,
  selectedPackage,
  packagePriority,
  coexistence,
  defaultVersionEntryPoint,
  verify,
  ...
}:
let
  newest = lib.last variants;
  tools = toolsFor newest.version;
  expected = tools.rust-analyzer;
  declaration = (capability allVersionsConfiguration).tools.rust-analyzer;
  reverseDeclaration = (capability reversedVersionsConfiguration).tools.rust-analyzer;
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
            languages = [ "override-language" ];
          };
        }
      ]
    );
  providerOverride = providerOverrideFor (map (variant: variant.path) variants) replacement;
  runtimeConfigurationsFor =
    selected:
    let
      selectedTools = toolsFor selected.version;
      forwarded = pkgs.writeShellScriptBin "rust-analyzer" ''
        exec ${selectedTools.rust-analyzer}/bin/rust-analyzer "$@"
      '';
      configuration = providerOverrideFor [ selected.path ] forwarded;
    in
    assert configuration.config.lmx.internal.rust.versions == [ selected.version ];
    {
      providerOverride = configuration;
      providerOverrideExpectedPackage = forwarded;
    };
  actual = (capability providerOverride).tools.rust-analyzer;
  forceOverride = evaluate (
    (map (variant: variant.path) variants)
    ++ [
      ({ lib, ... }: {
        lmx.capabilities.languageSupport.tools.rust-analyzer = lib.mkForce {
          package = replacement;
          command = "${replacement}/bin/rust-analyzer";
        };
      })
    ]
  );
in
{
  inherit runtimeConfigurationsFor;
  configurations = { inherit providerOverride; };
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    coexistence = coexistence [
      "rustc"
      "cargo"
      "rustfmt"
      "clippy"
      "rust-analyzer"
    ];
    providerSelection = verify "declaration and profile package select the same newest provider" (
      declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allVersionsConfiguration declaration.package
      && declaration.command == "${expected}/bin/rust-analyzer"
      && selectedPackage allVersionsConfiguration expected
      && builtins.toJSON declaration == builtins.toJSON reverseDeclaration
      && selectedPackage reversedVersionsConfiguration expected
      && !allVersionsConfiguration.config.programs.neovim.enable
      && !defaultConfiguration.config.programs.neovim.enable
    ) allVersionsConfiguration;
    userOverride = verify "ordinary definitions replace the complete provider declaration and package" (
      actual.package.outPath == replacement.outPath
      && actual.command == "${replacement}/bin/rust-analyzer"
      && actual.args == [ "--version" ]
      && actual.languages == [ "override-language" ]
      && selectedPackage providerOverride replacement
      && installedAsDeclared providerOverride replacement
    ) providerOverride;
    forceOverride = verify "mkForce replaces the complete provider including optional fields" (
      (capability forceOverride).tools.rust-analyzer.package.outPath == replacement.outPath
      && (capability forceOverride).tools.rust-analyzer.args == [ ]
      && (capability forceOverride).tools.rust-analyzer.languages == [ ]
      && selectedPackage forceOverride replacement
      && installedAsDeclared forceOverride replacement
    ) forceOverride;
  };
}
