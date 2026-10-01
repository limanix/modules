{ defaultConfiguration, verify, ... }:
{
  evaluation.optionalDocker = verify "selection does not implicitly enable Docker" (
    !defaultConfiguration.config.virtualisation.docker.enable
  ) defaultConfiguration;
}
