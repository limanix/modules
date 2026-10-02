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
  expected = tools.gopls;
  declaration = (capability allVersionsConfiguration).tools.gopls;
  reverseDeclaration = (capability reversedVersionsConfiguration).tools.gopls;
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
      forwarded = pkgs.writeShellScriptBin "gopls" ''
        exec ${selectedTools.gopls}/bin/gopls "$@"
      '';
      configuration = providerOverrideFor [ selected.path ] forwarded;
    in
    assert configuration.config.lmx.internal.go.versions == [ selected.version ];
    {
      providerOverride = configuration;
      providerOverrideExpectedPackage = forwarded;
    };
  actual = (capability providerOverride).tools.gopls;
  forceOverride = evaluate (
    (map (variant: variant.path) variants)
    ++ [
      ({ lib, ... }: {
        lmx.capabilities.languageSupport.tools.gopls = lib.mkForce {
          package = replacement;
          command = "${replacement}/bin/gopls";
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
      "go"
      "gopls"
      "delve"
    ];
    providerSelection = verify "declaration and profile package select the same newest provider" (
      declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allVersionsConfiguration declaration.package
      && declaration.command == "${expected}/bin/gopls"
      && declaration.languages == [ "go" ]
      && selectedPackage allVersionsConfiguration expected
      && builtins.toJSON declaration == builtins.toJSON reverseDeclaration
      && selectedPackage reversedVersionsConfiguration expected
      && !allVersionsConfiguration.config.programs.neovim.enable
      && !defaultConfiguration.config.programs.neovim.enable
    ) allVersionsConfiguration;
    userOverride = verify "ordinary definitions replace the complete provider declaration and package" (
      actual.package.outPath == replacement.outPath
      && actual.command == "${replacement}/bin/gopls"
      && actual.args == [ "version" ]
      && actual.languages == [ "override-language" ]
      && selectedPackage providerOverride replacement
      && installedAsDeclared providerOverride replacement
    ) providerOverride;
    forceOverride = verify "mkForce replaces the complete provider including optional fields" (
      (capability forceOverride).tools.gopls.package.outPath == replacement.outPath
      && (capability forceOverride).tools.gopls.args == [ ]
      && (capability forceOverride).tools.gopls.languages == [ ]
      && selectedPackage forceOverride replacement
      && installedAsDeclared forceOverride replacement
    ) forceOverride;
  };
}
