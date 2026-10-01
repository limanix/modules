{
  defaultConfiguration,
  capability,
  coexistence,
  defaultVersionEntryPoint,
  verify,
  ...
}:
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    coexistence = coexistence [ "nodejs" ];
    parserContribution = verify "parsers without a language server or editor" (
      (capability defaultConfiguration).tools == { }
      && (capability defaultConfiguration).languages != { }
      && !defaultConfiguration.config.programs.neovim.enable
    ) defaultConfiguration;
  };
}
