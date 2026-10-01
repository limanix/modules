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
  readChecks =
    selected: configuration: includeShared:
    let
      checks = import module.smoke {
        inherit (configuration) config pkgs;
        profile = profileFor configuration;
        inherit
          lib
          includeShared
          allVersionsConfiguration
          configurations
          profileFor
          ;
        inherit (selected) version;
        selector = selected.name;
      };
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
  versionCommands = builtins.concatMap (
    selected:
    derivations selected.name (readChecks selected versionConfigurations.${selected.version} false)
  ) module.variants;
in
if module.smoke == null then
  [ ]
else
  # Verify equivalence before sharing the default entry point's runtime checks.
  builtins.seq
    (if module.variants != [ ] && module.name != "k9s" then context.defaultVersionEntryPoint else true)
    (
      if module.variants != [ ] && defaultChecks ? commands then
        versionCommands
        ++ derivations module.name (builtins.removeAttrs defaultChecks [ "commands" ])
        # K9s's default entry point is a recommendation and has no versioned wrapper.
        ++ lib.optionals (module.name == "k9s") (
          derivations module.name { inherit (defaultChecks) commands; }
        )
      else
        derivations module.name defaultChecks
    )
