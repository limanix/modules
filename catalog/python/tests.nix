{
  variants,
  allVersionsConfiguration,
  reversedVersionsConfiguration,
  defaultConfiguration,
  versionConfigurations,
  toolsFor,
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
  runtimeOutputSelection =
    variant:
    let
      configuration = versionConfigurations.${variant.version};
      tools = toolsFor variant.version;
      priority =
        lib.meta.defaultPriority
        - builtins.length (
          builtins.filter (other: lib.versionOlder other.version variant.version) variants
        );
      installed = lib.findFirst (
        package: toString package == tools.python.outPath
      ) null configuration.config.environment.systemPackages;
      profile = pkgs.buildEnv {
        name = "python-${variant.version}-runtime-output-selection";
        paths = [ installed ];
        extraOutputsToInstall = [
          "doc"
          "man"
          "info"
        ];
      };
      selected = map toString (lib.concatMap (entry: entry.paths) profile.chosenOutputs);
    in
    installed != null
    && installed.outPath == tools.python.outPath
    && installed.drvPath == tools.python.drvPath
    && installed.interpreter == tools.python.interpreter
    && installed.version == tools.python.version
    && builtins.elem tools.python.outPath selected
    && !(builtins.elem tools.python.doc.outPath selected)
    && selectedPackage configuration tools.python
    && packagePriority installed == priority
    && installedAsDeclared configuration (lib.setPrio priority tools.python);
  expected = pkgs.pyright;
  declaration = (capability allVersionsConfiguration).tools.pyright;
  reverseDeclaration = (capability reversedVersionsConfiguration).tools.pyright;
  replacement = pkgs.writeShellScriptBin "pyright-langserver" ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${expected}/bin/pyright-langserver "$@"
  '';
  providerModule = {
    lmx.capabilities.languageSupport.tools.pyright = {
      package = replacement;
      command = "${replacement}/bin/pyright-langserver";
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
    assert configuration.config.lmx.internal.python.versions == [ selected.version ];
    {
      providerOverride = configuration;
    };
  actual = (capability providerOverride).tools.pyright;
  forceOverride = evaluate (
    (map (variant: variant.path) variants)
    ++ [
      ({ lib, ... }: {
        lmx.capabilities.languageSupport.tools.pyright = lib.mkForce {
          package = replacement;
          command = "${replacement}/bin/pyright-langserver";
        };
      })
    ]
  );
in
{
  inherit runtimeConfigurationsFor;
  configurations = { inherit providerOverride; };
  evaluation = {
    runtimeOutputSelection =
      verify "every interpreter retains runtime identity without implicit HTML docs"
        (builtins.all runtimeOutputSelection variants)
        defaultConfiguration;
    defaultEntryPoint = defaultVersionEntryPoint;
    coexistence = coexistence [
      "python"
      "virtualenv"
    ];
    providerSelection = verify "the final language server declaration and profile agree" (
      declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allVersionsConfiguration declaration.package
      && declaration.command == "${expected}/bin/pyright-langserver"
      && declaration.args == [ "--stdio" ]
      && declaration.languages == [ "python" ]
      && selectedPackage allVersionsConfiguration expected
      && builtins.toJSON declaration == builtins.toJSON reverseDeclaration
      && selectedPackage reversedVersionsConfiguration expected
      && !allVersionsConfiguration.config.programs.neovim.enable
      && !defaultConfiguration.config.programs.neovim.enable
    ) allVersionsConfiguration;
    userOverride = verify "ordinary definitions replace the complete provider declaration and package" (
      actual.package.outPath == replacement.outPath
      && actual.command == "${replacement}/bin/pyright-langserver"
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
      (capability forceOverride).tools.pyright.package.outPath == replacement.outPath
      && (capability forceOverride).tools.pyright.args == [ ]
      && (capability forceOverride).tools.pyright.languages == [ ]
      && selectedPackage forceOverride replacement
      && installedAsDeclared forceOverride replacement
    ) forceOverride;
  };
}
