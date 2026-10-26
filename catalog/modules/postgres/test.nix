{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
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
    let
      tools = toolsFor configuration line;
      warning = "PostgreSQL ${tools.postgres.version} no longer receives upstream security updates.";
    in
    installed configuration tools.postgres
    && installed configuration tools.pgConfig
    && builtins.elem "/share/postgresql" configuration.config.environment.pathsToLink
    && (builtins.elem warning configuration.config.warnings == (tools.endOfLife == true));
  commands =
    line: configuration:
    let
      tools = toolsFor configuration line;
      profile = profileFor configuration;
    in
    pkgs.runCommand "postgres-${line}-commands-smoke" { } ''
      for executable in ${tools.postgres}/bin/* ${tools.pgConfig}/bin/*; do
        test -x "${profile}/bin/$(basename "$executable")-${line}"
      done
      ${profile}/bin/psql-${line} --version | grep -F '${tools.postgres.version}'
      ${profile}/bin/pg_config-${line} --version | grep -F '${tools.postgres.version}'
      test "$(${profile}/bin/pg_config-${line} --bindir)" = "${tools.postgres}/bin"
      test -d "$(${profile}/bin/pg_config-${line} --includedir)"
      test -d "$(${profile}/bin/pg_config-${line} --includedir-server)"
      test -d "$(${profile}/bin/pg_config-${line} --libdir)"
      test -f "$(${profile}/bin/pg_config-${line} --pgxs)"
      ${profile}/bin/postgres-${line} --version | grep -F '${tools.postgres.version}'
      test -d ${profile}/share/postgresql
      touch "$out"
    '';
  lineTests = import ../../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: valid configuration line;
    runLine = { line, configuration }: commands line configuration;
  };
  inherit (lineTests)
    metadata
    lines
    configurations
    defaultConfiguration
    allConfiguration
    ;
  newestTools = toolsFor allConfiguration (lib.last lines);
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
    allLines = import ../../_shared/test/profile-commands.nix {
      inherit pkgs;
      profile = profileFor allConfiguration;
      expectedCommands = {
        psql = "${newestTools.postgres}/bin/psql";
        postgres = "${newestTools.postgres}/bin/postgres";
        pg_dump = "${newestTools.postgres}/bin/pg_dump";
        pg_restore = "${newestTools.postgres}/bin/pg_restore";
        pg_config = "${newestTools.pgConfig}/bin/pg_config";
      };
    };
    lifecycle = import ./test/lifecycle.nix {
      inherit pkgs;
      profile = profileFor defaultConfiguration;
      line = metadata.default;
    };
  };
}
