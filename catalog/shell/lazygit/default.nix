{ config, lib, ... }:
let
  inherit (config.lmx.capabilities.theme) name palette;
in
{
  imports = [ ./help.nix ];

  programs.git.enable = true;

  programs.lazygit = {
    enable = true;
    # Lazygit's own theme uses the terminal's colors, which the system theme asks for.
    settings.gui = lib.mkIf (name != "system") {
      theme = lib.mapAttrs (_: lib.mkDefault) {
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
      authorColors."*" = lib.mkDefault palette.blue;
    };
    # The platform's pbcopy sends the text through the terminal to the Mac clipboard.
    settings.os.copyToClipboardCmd = lib.mkDefault "printf %s {{text}} | pbcopy";
  };
}
