{ config, hasPackage, ... }:
let
  inherit (config.lmx.capabilities.theme) flavor palette;
  inherit (config.programs.lazygit) settings;
  expectedTheme = {
    activeBorderColor = [
      palette.blue
      "bold"
    ];
    inactiveBorderColor = [ palette.subtext0 ];
    optionsTextColor = [ palette.blue ];
    selectedLineBgColor = [ palette.surface0 ];
    cherryPickedCommitBgColor = [ palette.surface1 ];
    cherryPickedCommitFgColor = [ palette.blue ];
    unstagedChangesColor = [ palette.red ];
    defaultFgColor = [ palette.text ];
    searchingActiveBorderColor = [ palette.yellow ];
  };
in
config.programs.git.enable
&& config.programs.lazygit.enable
&& hasPackage config.programs.git.package
&& hasPackage config.programs.lazygit.package
&& (
  if flavor == "system" then
    !(settings ? gui)
  else
    settings.gui.theme == expectedTheme && settings.gui.authorColors."*" == palette.lavender
)
