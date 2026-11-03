{ config, lib, ... }:
let
  inherit (config.lmx.capabilities.theme) name palette;
in
{
  imports = [ ./help.nix ];

  programs.git.enable = true;

  programs.lazygit = {
    enable = true;

    # Keep Lazygit's terminal colors for the system theme.
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

    # Use the Mac clipboard through the platform's pbcopy.
    settings.os.copyToClipboardCmd = lib.mkDefault "printf %s {{text}} | pbcopy";
  };
}
