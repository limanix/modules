{
  defaultConfiguration,
  emptyConfiguration,
  startup,
  verify,
  ...
}:
{
  evaluation.noStartup = verify "cloud clients add no startup units or activation commands" (
    startup defaultConfiguration == startup emptyConfiguration
  ) defaultConfiguration;
}
