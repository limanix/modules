{ config, hasPackage, ... }:
let
  inherit (builtins.fromTOML (builtins.readFile ../../_shared/palette.toml)) mocha;
  expectedTheme = {
    activeBorderColor = [
      mocha.blue
      "bold"
    ];
    inactiveBorderColor = [ mocha.subtext0 ];
    optionsTextColor = [ mocha.blue ];
    selectedLineBgColor = [ mocha.surface0 ];
    cherryPickedCommitBgColor = [ mocha.surface1 ];
    cherryPickedCommitFgColor = [ mocha.blue ];
    unstagedChangesColor = [ mocha.red ];
    defaultFgColor = [ mocha.text ];
    searchingActiveBorderColor = [ mocha.yellow ];
  };
in
config.programs.git.enable
&& config.programs.lazygit.enable
&& hasPackage config.programs.git.package
&& hasPackage config.programs.lazygit.package
&& config.programs.lazygit.settings.gui.theme == expectedTheme
&& config.programs.lazygit.settings.gui.authorColors."*" == mocha.lavender
