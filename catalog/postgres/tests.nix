{
  variants,
  defaultConfiguration,
  emptyConfiguration,
  evaluate,
  pkgs,
  toolsFor,
  selectedPackage,
  startup,
  coexistence,
  defaultVersionEntryPoint,
  verify,
  ...
}:
let
  selected = builtins.head variants;
  tools = toolsFor selected.version;
  withService = evaluate [
    selected.path
    {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
      };
    }
  ];
in
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    coexistence = coexistence [ "postgres" ];
    serviceIndependence = verify "command selection does not start a database service" (
      !defaultConfiguration.config.services.postgresql.enable
      && !(defaultConfiguration.config.systemd.services ? postgresql)
      && startup defaultConfiguration == startup emptyConfiguration
    ) defaultConfiguration;
    servicePackagePrecedence =
      verify "catalog commands outrank the independently selected service package"
        (
          withService.config.services.postgresql.enable
          && withService.config.services.postgresql.package.outPath == pkgs.postgresql_18.outPath
          && selectedPackage withService tools.postgres
        )
        withService;
  };
}
