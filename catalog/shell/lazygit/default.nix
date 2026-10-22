{ config, lib, ... }:
let
  inherit (config.lmx.capabilities.theme) flavor palette;
in
{
  imports = [ ./help.nix ];

  programs.git.enable = true;

  programs.lazygit = {
    enable = true;
    # Lazygit's own theme uses the terminal's colors, which the system flavor asks for.
    settings.gui = lib.mkIf (flavor != "system") {
      theme = lib.mapAttrs (_: lib.mkDefault) {
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
      authorColors."*" = lib.mkDefault palette.lavender;
    };
    # The platform's pbcopy sends the text through the terminal to the Mac clipboard.
    settings.os.copyToClipboardCmd = lib.mkDefault "printf %s {{text}} | pbcopy";
  };
}
