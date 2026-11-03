{ config, hasPackage, ... }:
let
  inherit (config.lmx.capabilities.theme) name palette;
  inherit (config.programs.lazygit) settings;
  expectedTheme = {
    activeBorderColor = [
      palette.accent
      "bold"
    ];
    inactiveBorderColor = [ palette.border ];
    optionsTextColor = [ palette.blue ];
    selectedLineBgColor = [ palette.surface ];
    cherryPickedCommitBgColor = [ palette.selection ];
    cherryPickedCommitFgColor = [ palette.blue ];
    unstagedChangesColor = [ palette.red ];
    defaultFgColor = [ palette.foreground ];
    searchingActiveBorderColor = [ palette.yellow ];
  };
in
config.programs.git.enable
&& config.programs.lazygit.enable
&& hasPackage config.programs.git.package
&& hasPackage config.programs.lazygit.package
&& (
  if name == "system" then
    !(settings ? gui)
  else
    settings.gui.theme == expectedTheme && settings.gui.authorColors."*" == palette.blue
)
