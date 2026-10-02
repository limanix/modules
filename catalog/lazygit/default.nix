{ lib, ... }:
let
  inherit (builtins.fromTOML (builtins.readFile ../_shared/palette.toml)) mocha;
in
{
  imports = [ ../git/default.nix ];

  programs.lazygit = {
    enable = true;
    settings.gui = {
      theme = lib.mapAttrs (_: lib.mkDefault) {
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
      authorColors."*" = lib.mkDefault mocha.lavender;
    };
  };
}
