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
    selectedPackage
    ;
  toolsFor = configuration: line: configuration.config.lmx.internal.minikube.packages.${line};
  valid =
    configuration: line:
    import ./test/check.nix {
      inherit (configuration) config;
      tools = toolsFor configuration line;
      hasPackage = installed configuration;
    };
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: valid configuration line;
    runLine =
      { line, configuration }:
      (import ./test/smoke.nix {
        inherit pkgs profileFor;
        profile = profileFor configuration;
        version = line;
        tools = toolsFor configuration line;
        newestTools = toolsFor configuration line;
        allVersionsConfiguration = configuration;
        includeShared = false;
      }).commands;
  };
  inherit (lineTests)
    metadata
    lines
    defaultConfiguration
    allConfiguration
    ;
  newestTools = toolsFor allConfiguration (lib.last lines);
  sharedChecks = import ./test/smoke.nix {
    inherit pkgs profileFor newestTools;
    profile = profileFor allConfiguration;
    version = lib.last lines;
    tools = newestTools;
    allVersionsConfiguration = allConfiguration;
    includeShared = true;
  };
  emptyConfiguration = evaluate [ ];
  dependencyMetadata = builtins.fromTOML (builtins.readFile ../k9s/module.toml);
  explicitDependency = ../k9s/versions + "/${builtins.head dependencyMetadata.versions}.nix";
  explicitConfiguration = evaluate [
    ./default.nix
    explicitDependency
  ];
  startup =
    configuration:
    # Installing packages changes these generated NixOS dependencies. Keep every
    # unit, enabled flag and activation command in the comparison.
    builtins.toJSON {
      units = builtins.mapAttrs (name: unit: {
        inherit (unit) enable;
        text =
          if name == "dbus-broker.service" then
            lib.replaceStrings
              [
                "X-Restart-Triggers=${
                  configuration.config.systemd.services.dbus-broker.unitConfig."X-Restart-Triggers"
                }"
              ]
              [ "X-Restart-Triggers=<dbus-restart-triggers>" ]
              unit.text
          else
            unit.text;
      }) configuration.config.systemd.units;
      activation =
        lib.replaceStrings [ "${configuration.config.system.build.etc}/etc" ] [ "<generated-etc>/etc" ]
          configuration.config.system.activationScripts.script;
    };
in
{
  eval = lineTests.eval // {
    allLines = verify "Selected lines retain their packages and the newest ordinary commands" (
      builtins.all (line: valid allConfiguration line) lines
      && selectedPackage allConfiguration newestTools.minikube
    ) allConfiguration;
    explicitDependency = valid explicitConfiguration metadata.default;
    noStartup = startup defaultConfiguration == startup emptyConfiguration;
    optionalDocker = !defaultConfiguration.config.virtualisation.docker.enable;
  };
  run = lineTests.run // {
    allLines = sharedChecks.coexistence;
    dependency = pkgs.runCommand "minikube-k9s-public-dependency" { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      ${profileFor defaultConfiguration}/bin/k9s version > "$out"
      test -s "$out"
    '';
  };
}
