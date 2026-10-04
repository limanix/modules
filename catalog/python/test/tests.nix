{
  variants,
  allConfiguration,
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
  declaration = (capability allConfiguration).tools.pyright;
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
    };
  };
  providerOverride = evaluate ((map (variant: variant.path) variants) ++ [ providerModule ]);
in
{
  configurations = {
    userOverride = providerOverride;
  };
  evaluation = {
    runtimeOutputSelection =
      verify "every interpreter retains runtime identity without implicit HTML docs"
        (builtins.all runtimeOutputSelection variants)
        allConfiguration;
    allLines = verify "the final language server declaration and profile agree" (
      coexistence [
        "python"
        "virtualenv"
      ]
      && declaration.package.outPath == expected.outPath
      && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length variants - 1)
      && installedAsDeclared allConfiguration declaration.package
      && declaration.command == "${expected}/bin/pyright-langserver"
      && declaration.args == [ "--stdio" ]
      && declaration.languages == [ "python" ]
      && selectedPackage allConfiguration expected
      && !allConfiguration.config.programs.neovim.enable
    ) allConfiguration;
    userOverride = verify "the selected replacement provider is installed in the system profile" (
      selectedPackage providerOverride replacement && installedAsDeclared providerOverride replacement
    ) providerOverride;
  };
}
