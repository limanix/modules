{
  componentChecks,
  defaultConfiguration,
  lib,
  verify,
  ...
}:
{
  evaluation = {
    composition = componentChecks;
    noExamples = verify "workbench does not install example applications" (
      !builtins.any (
        path: path == "limanix/examples/cozy" || lib.hasPrefix "limanix/examples/cozy/" path
      ) (builtins.attrNames defaultConfiguration.config.environment.etc)
    ) defaultConfiguration;
  };
}
