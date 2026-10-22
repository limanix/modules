{
  evaluate,
  defaultConfiguration,
  verify,
  ...
}:
let
  # The managed colors exist with a Catppuccin flavor.
  mocha = {
    lmx.capabilities.theme.flavor = "mocha";
  };
  managed = evaluate [
    ../default.nix
    mocha
  ];
  overridden = evaluate [
    ../default.nix
    mocha
    { programs.lazygit.settings.gui.theme.activeBorderColor = [ "red" ]; }
  ];
in
{
  clipboard = verify "copies go to the Mac clipboard through the platform's pbcopy" (
    defaultConfiguration.config.programs.lazygit.settings.os.copyToClipboardCmd
    == "printf %s {{text}} | pbcopy"
  ) defaultConfiguration;
  themeOverride = verify "managed Mocha colors accept ordinary user settings" (
    managed.config.programs.lazygit.settings.gui.theme.activeBorderColor == [
      "#89b4fa"
      "bold"
    ]
    && overridden.config.programs.lazygit.settings.gui.theme.activeBorderColor == [ "red" ]
    && overridden.config.programs.lazygit.enable
    && overridden.config.programs.git.enable
  ) overridden;
}
