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
  # Posting crashes on Textual's terminal themes; the system flavor keeps Mocha.
  environment.variables.POSTING_THEME = lib.mkDefault (
    if flavor == "system" then "catppuccin-mocha" else "catppuccin-${flavor}"
  );
}
