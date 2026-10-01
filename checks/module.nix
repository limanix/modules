{
  catalog,
  module,
  nixpkgs,
  system,
  userName,
}:
let
  evaluate =
    modules:
    import ./nixos.nix {
      inherit
        nixpkgs
        system
        userName
        modules
        ;
    };
  defaultConfiguration = evaluate [ module.path ];
  emptyConfiguration = evaluate [ ];
  inherit (defaultConfiguration) lib pkgs;
  variants = builtins.sort (left: right: lib.versionOlder left.version right.version) module.variants;
  versionConfigurations = builtins.listToAttrs (
    map (variant: {
      name = variant.version;
      value = evaluate [ variant.path ];
    }) variants
  );
  allVersionsConfiguration = evaluate (map (variant: variant.path) variants);
  reversedVersionsConfiguration = evaluate (map (variant: variant.path) (lib.reverseList variants));
  hasPackage =
    configuration: package:
    builtins.any (
      installed: installed.outPath == package.outPath
    ) configuration.config.environment.systemPackages;
  checkResult =
    configuration: selected:
    import selected.check {
      inherit (configuration) config pkgs;
      inherit (selected) version;
      inherit userName;
      hasPackage = hasPackage configuration;
    };
  result =
    configuration:
    assert import ./ownership.nix { inherit (configuration) lib options; };
    configuration.config.system.build.toplevel.drvPath;
  verify =
    label: valid: configuration:
    builtins.trace "Checking ${system}: ${module.name}: ${label}" (
      builtins.addErrorContext "while checking ${module.name}: ${label} on ${system}" (
        if valid then result configuration else throw "Module result: ${module.name}: ${label}"
      )
    );
  publicValues =
    configuration:
    builtins.toJSON {
      inherit (configuration.config) limanix;
      lmx = builtins.removeAttrs configuration.config.lmx [ "internal" ];
    };
  sameResult =
    original: repeated:
    result original == result repeated && publicValues original == publicValues repeated;
  packagePriority = package: package.meta.priority or lib.meta.defaultPriority;
  profileFor =
    configuration:
    configuration.config.system.path.overrideAttrs (previous: {
      passthru = previous.passthru // {
        paths = builtins.filter (
          package:
          !(builtins.any (
            original: original.outPath == package.outPath && packagePriority original == packagePriority package
          ) emptyConfiguration.config.environment.systemPackages)
        ) configuration.config.environment.systemPackages;
      };
    });
  installedAsDeclared =
    configuration: package:
    builtins.any (
      installed:
      installed.outPath == package.outPath && packagePriority installed == packagePriority package
    ) configuration.config.environment.systemPackages;
  selectedPackage =
    configuration: package:
    let
      candidates = builtins.filter (
        candidate: (candidate.pname or null) == (package.pname or null)
      ) configuration.config.environment.systemPackages;
      matching = builtins.filter (candidate: candidate.outPath == package.outPath) candidates;
    in
    matching != [ ]
    && builtins.all (
      candidate:
      candidate.outPath == package.outPath
      || builtins.any (winner: packagePriority winner < packagePriority candidate) matching
    ) candidates;
  configurationFor =
    selected:
    if selected.version == null || selected.path == module.path then
      defaultConfiguration
    else
      versionConfigurations.${selected.version};
  componentChecks = builtins.listToAttrs (
    lib.concatMap (
      selected:
      let
        original = configurationFor selected;
        components = import ./component-imports.nix {
          inherit catalog selected;
          inherit (original) graph;
        };
        repeated = evaluate ([ selected.path ] ++ components);
      in
      lib.optional (components != [ ]) {
        inherit (selected) name;
        value = verify "${selected.name} with repeated components" (
          checkResult repeated selected && sameResult original repeated
        ) original;
      }
    ) ([ module ] ++ variants)
  );
  coexistence =
    packageNames:
    let
      newest = toolsFor (lib.last variants).version;
    in
    verify "coexisting lines and ordinary package selection" (
      builtins.all (checkResult allVersionsConfiguration) variants
      && builtins.all (checkResult reversedVersionsConfiguration) variants
      && builtins.all (
        name:
        selectedPackage allVersionsConfiguration newest.${name}
        && selectedPackage reversedVersionsConfiguration newest.${name}
      ) packageNames
    ) allVersionsConfiguration;
  toolsFor = version: import (module.directory + "/packages.nix") { inherit system version; };
  defaultVersionEntryPoint =
    let
      explicit = versionConfigurations.${module.version};
    in
    verify "default and explicit default entry points" (sameResult defaultConfiguration explicit)
      explicit;
  startup =
    configuration:
    lib.replaceStrings
      [
        (toString configuration.config.system.build.etc)
        configuration.config.systemd.services.dbus-broker.unitConfig."X-Restart-Triggers"
      ]
      [ "<generated-etc>" "<dbus-restart-triggers>" ]
      (
        builtins.toJSON {
          units = builtins.mapAttrs (_: unit: {
            inherit (unit) enable text;
          }) configuration.config.systemd.units;
          activation = configuration.config.system.activationScripts.script;
        }
      );
  context = {
    inherit
      catalog
      module
      system
      userName
      evaluate
      defaultConfiguration
      emptyConfiguration
      profileFor
      versionConfigurations
      allVersionsConfiguration
      reversedVersionsConfiguration
      variants
      pkgs
      lib
      verify
      packagePriority
      installedAsDeclared
      selectedPackage
      componentChecks
      coexistence
      toolsFor
      defaultVersionEntryPoint
      startup
      ;
    installed = hasPackage;
    capability = configuration: configuration.config.lmx.capabilities.languageSupport;
    configurations = localTests.configurations or { };
  };
  testFile = module.directory + "/tests.nix";
  localTests = if builtins.pathExists testFile then import testFile context else { };
in
context
// {
  evaluation = {
    default =
      verify "default configuration" (checkResult defaultConfiguration module)
        defaultConfiguration;
    versions = builtins.listToAttrs (
      map (variant: {
        name = variant.version;
        value = verify "${variant.name} configuration" (checkResult versionConfigurations.${variant.version}
          variant
        ) versionConfigurations.${variant.version};
      }) variants
    );
  }
  // (localTests.evaluation or { });
  diagnostics = localTests.diagnostics or { };
}
