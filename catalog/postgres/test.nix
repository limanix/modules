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
  toolsFor = configuration: line: configuration.config.lmx.internal.postgres.packages.${line};
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
    configurations
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
  serviceLine = builtins.head lines;
  serviceTools = toolsFor configurations.${serviceLine} serviceLine;
  withService = evaluate [
    (./versions + "/${serviceLine}.nix")
    {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
      };
    }
  ];
in
{
  eval = lineTests.eval // {
    allLines = verify "Selected lines retain their packages and the newest ordinary commands" (
      builtins.all (line: valid allConfiguration line) lines
      && selectedPackage allConfiguration newestTools.postgres
      && selectedPackage allConfiguration newestTools.pgConfig
    ) allConfiguration;
    noService =
      !defaultConfiguration.config.services.postgresql.enable
      && !(defaultConfiguration.config.systemd.services ? postgresql);
    servicePackagePrecedence = verify "Catalog commands outrank an independently selected service" (
      withService.config.services.postgresql.enable
      && withService.config.services.postgresql.package.outPath == pkgs.postgresql_18.outPath
      && selectedPackage withService serviceTools.postgres
      && selectedPackage withService serviceTools.pgConfig
    ) withService;
  };
  run = lineTests.run // {
    allLines = sharedChecks.coexistence;
    lifecycle = import ./test/lifecycle.nix {
      inherit pkgs;
      profile = profileFor defaultConfiguration;
      line = metadata.default;
    };
  };
}
