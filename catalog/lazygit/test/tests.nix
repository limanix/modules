{
  evaluate,
  defaultConfiguration,
  verify,
  ...
}:
let
  overridden = evaluate [
    ../default.nix
    { programs.lazygit.settings.gui.theme.activeBorderColor = [ "red" ]; }
  ];
in
{
  themeOverride = verify "managed Mocha colors accept ordinary user settings" (
    defaultConfiguration.config.programs.lazygit.settings.gui.theme.activeBorderColor == [
      "#89b4fa"
      "bold"
    ]
    && overridden.config.programs.lazygit.settings.gui.theme.activeBorderColor == [ "red" ]
    && overridden.config.programs.lazygit.enable
    && overridden.config.programs.git.enable
  ) overridden;
}
