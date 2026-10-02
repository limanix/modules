context:
let
  inherit (context)
    module
    system
    lib
    defaultConfiguration
    versionConfigurations
    allVersionsConfiguration
    configurations
    profileFor
    ;
  runtime = import ./runtime-selection.nix {
    profile = context.runtimeProfile or "all";
    versions = context.runtimeVersions or [ ];
    modules = [ module ];
  };
  readChecks =
    selected: configuration: includeShared:
    let
      configurationsFor = context.runtimeConfigurationsFor or (_: configurations);
      smokeConfigurations =
        if runtime.profile == "pr" then
          assert
            builtins.isFunction configurationsFor
            || throw "Module smoke: ${module.name}.runtimeConfigurationsFor must be a function";
          let
            scoped = configurationsFor selected;
          in
          assert
            builtins.isAttrs scoped
            || throw "Module smoke: ${selected.name}.runtimeConfigurationsFor must return an attribute set";
          scoped
        else
          configurations;
      checks = builtins.seq smokeConfigurations (
        import module.smoke {
          inherit (configuration) config pkgs;
          profile = profileFor configuration;
          inherit
            lib
            includeShared
            allVersionsConfiguration
            profileFor
            ;
          configurations = smokeConfigurations;
          inherit (selected) version;
          selector = selected.name;
        }
      );
    in
    assert
      builtins.isAttrs checks && checks != { }
      || throw "Module smoke: ${selected.name} must return a nonempty attribute set";
    checks;
  derivations =
    label: checks:
    builtins.map (
      name:
      let
        check = checks.${name};
      in
      assert lib.isDerivation check || throw "Module smoke: ${label}.${name} must be a derivation";
      assert
        check.system == system
        || throw "Module smoke: ${label}.${name} targets ${check.system}, expected ${system}";
      builtins.addErrorContext "while instantiating catalog smoke ${label}.${name}" (
        builtins.trace "Smoke ${label}.${name}: ${check.drvPath}" check
      )
    ) (builtins.attrNames checks);
  defaultChecks = readChecks module defaultConfiguration true;
  commandsFor =
    variants:
    builtins.concatMap (
      selected:
      derivations selected.name (readChecks selected versionConfigurations.${selected.version} false)
    ) variants;
  versionCommands = commandsFor module.variants;
  requestedVariants = builtins.filter (
    selected: builtins.elem selected.version runtime.versions
  ) module.variants;
  currentChecks = builtins.removeAttrs defaultChecks [ "coexistence" ];
in
builtins.deepSeq runtime (
  if module.smoke == null then
    [ ]
  else if runtime.profile == "pr" then
    # Preserve current startup and override corners; historical coexistence belongs to full coverage.
    assert currentChecks != { } || throw "Module smoke: ${module.name} needs a current runtime check";
    derivations module.name currentChecks ++ commandsFor requestedVariants
  else if module.variants != [ ] && defaultChecks ? commands then
    versionCommands
    ++ derivations module.name (builtins.removeAttrs defaultChecks [ "commands" ])
    # Share commands only when full system and public option values agree.
    # Recommendation-style defaults can intentionally differ from a version.
    ++ lib.optionals (!context.defaultVersionEquivalent) (
      derivations module.name { inherit (defaultChecks) commands; }
    )
  else if module.variants != [ ] then
    # Modules without a commands check still need each line's startup/build checks.
    versionCommands ++ derivations module.name defaultChecks
  else
    derivations module.name defaultChecks
)
