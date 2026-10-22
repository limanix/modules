{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities.theme) flavor;
in
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.posting ];
  # Textual's ANSI theme draws in the terminal's colors and on its background.
  environment.variables.POSTING_THEME = lib.mkDefault (
    if flavor == "system" then "ansi-dark" else "catppuccin-${flavor}"
  );
}
