{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers)
    evaluate
    profileFor
    verify
    installed
    installedAsDeclared
    selectedPackage
    packagePriority
    ;
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: checkResult configuration line;
    runLine = { line, configuration }: (runtimeFor line configuration false).commands;
  };
  inherit (lineTests) metadata lines allConfiguration;
  versionConfigurations = lineTests.configurations;
  variants = map (version: {
    inherit version;
    path = ./versions + "/${version}.nix";
  }) lines;
  toolsFor = line: versionConfigurations.${line}.config.lmx.internal.nodejs.packages.${line};
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  checkResult =
    configuration: line:
    import ./test/check.nix {
      inherit (configuration) config;
      inherit pkgs;
      tools = toolsFor line;
      hasPackage = installed configuration;
    };
  coexistence =
    packageNames:
    let
      newest = toolsFor (lib.last lines);
    in
    verify "nodejs: explicit lines coexist and select the newest ordinary commands" (
      builtins.all (variant: checkResult allConfiguration variant.version) variants
      && builtins.all (name: selectedPackage allConfiguration newest.${name}) packageNames
    ) allConfiguration;
  localTests = import ./test/tests.nix {
    inherit
      pkgs
      lib
      variants
      versionConfigurations
      allConfiguration
      toolsFor
      capability
      evaluate
      verify
      installedAsDeclared
      selectedPackage
      packagePriority
      coexistence
      ;
  };
  runtimeFor =
    line: configuration: includeShared:
    import ./test/smoke.nix {
      inherit
        pkgs
        includeShared
        allConfiguration
        profileFor
        ;
      inherit (configuration) config;
      version = line;
      profile = profileFor configuration;
      tools = toolsFor line;
      olderTools = toolsFor (builtins.head lines);
      expectedTools = toolsFor (lib.last lines);
      inherit (localTests) configurations;
    };
  sharedRuntime = builtins.removeAttrs (runtimeFor metadata.default
    versionConfigurations.${metadata.default}
    true
  ) [ "commands" ];
in
{
  eval = lineTests.eval // localTests.evaluation;
  run = lineTests.run // sharedRuntime;
  builds = builtins.listToAttrs (
    lib.concatMap (
      line:
      let
        tools = toolsFor line;
      in
      lib.optional (tools ? npm) {
        name = "npm-${line}";
        value = tools.npm;
      }
    ) lines
  );
}
