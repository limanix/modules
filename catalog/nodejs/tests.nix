{
  variants,
  allVersionsConfiguration,
  reversedVersionsConfiguration,
  defaultConfiguration,
  evaluate,
  pkgs,
  lib,
  capability,
  installedAsDeclared,
  selectedPackage,
  packagePriority,
  coexistence,
  defaultVersionEntryPoint,
  verify,
  ...
}:
let
  expected = pkgs.typescript-language-server;
  declaration = (capability allVersionsConfiguration).tools.typescript-language-server;
  reverseDeclaration = (capability reversedVersionsConfiguration).tools.typescript-language-server;
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
      languages = [ "override-language" ];
    };
  };
  providerOverride = evaluate ((map (variant: variant.path) variants) ++ [ providerModule ]);
  runtimeConfigurationsFor =
    selected:
    let
      configuration = evaluate [
        selected.path
        providerModule
      ];
    in
    assert configuration.config.lmx.internal.nodejs.versions == [ selected.version ];
    {
      providerOverride = configuration;
    };
  actual = (capability providerOverride).tools.typescript-language-server;
  forceOverride = evaluate (
    (map (variant: variant.path) variants)
    ++ [
      ({ lib, ... }: {
        lmx.capabilities.languageSupport.tools.typescript-language-server = lib.mkForce {
          package = replacement;
          command = "${replacement}/bin/typescript-language-server";
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
    coexistence = coexistence [ "nodejs" ];
    providerSelection = verify "the final language server declaration and profile agree" (
      declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allVersionsConfiguration declaration.package
      && declaration.command == "${expected}/bin/typescript-language-server"
      && declaration.args == [ "--stdio" ]
      &&
        declaration.languages == [
          "javascript"
          "typescript"
        ]
      && selectedPackage allVersionsConfiguration expected
      && builtins.toJSON declaration == builtins.toJSON reverseDeclaration
      && selectedPackage reversedVersionsConfiguration expected
      && !allVersionsConfiguration.config.programs.neovim.enable
      && !defaultConfiguration.config.programs.neovim.enable
    ) allVersionsConfiguration;
    userOverride = verify "ordinary definitions replace the complete provider declaration and package" (
      actual.package.outPath == replacement.outPath
      && actual.command == "${replacement}/bin/typescript-language-server"
      &&
        actual.args == [
          "--catalog-smoke"
          "--stdio"
        ]
      && actual.languages == [ "override-language" ]
      && selectedPackage providerOverride replacement
      && installedAsDeclared providerOverride replacement
    ) providerOverride;
    forceOverride = verify "mkForce replaces the complete provider including optional fields" (
      (capability forceOverride).tools.typescript-language-server.package.outPath == replacement.outPath
      && (capability forceOverride).tools.typescript-language-server.args == [ ]
      && (capability forceOverride).tools.typescript-language-server.languages == [ ]
      && selectedPackage forceOverride replacement
      && installedAsDeclared forceOverride replacement
    ) forceOverride;
  };
}
