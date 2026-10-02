{
  componentChecks,
  module,
  evaluate,
  defaultConfiguration,
  verify,
  ...
}:
let
  overridden = evaluate [
    module.path
    {
      programs.lazygit.settings.gui.theme.activeBorderColor = [ "red" ];
    }
  ];
in
{
  evaluation.composition = componentChecks;
  evaluation.theme = verify "Mocha colors accept ordinary user settings" (
    defaultConfiguration.config.programs.lazygit.settings.gui.theme.activeBorderColor == [
      "#89b4fa"
      "bold"
    ]
    && overridden.config.programs.lazygit.settings.gui.theme.activeBorderColor == [ "red" ]
  ) overridden;
}
