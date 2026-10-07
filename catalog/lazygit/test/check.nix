{ config, hasPackage, ... }:
let
  inherit (config.lmx.capabilities.theme) palette;
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
&& config.programs.lazygit.settings.gui.theme == expectedTheme
&& config.programs.lazygit.settings.gui.authorColors."*" == palette.lavender
