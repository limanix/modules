{
  defaultConfiguration,
  emptyConfiguration,
  startup,
  componentChecks,
  coexistence,
  defaultVersionEntryPoint,
  verify,
  ...
}:
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    composition = componentChecks;
    coexistence = coexistence [ "minikube" ];
    noStartup = verify "selection adds no startup units or activation commands" (
      startup defaultConfiguration == startup emptyConfiguration
    ) defaultConfiguration;
    optionalDocker = verify "selection does not implicitly enable Docker" (
      !defaultConfiguration.config.virtualisation.docker.enable
    ) defaultConfiguration;
  };
}
