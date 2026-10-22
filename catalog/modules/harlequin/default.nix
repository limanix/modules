{ config, pkgs, ... }:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [
    (import ./package.nix {
      inherit pkgs;
      # Harlequin refuses Textual's terminal theme, so the system flavor keeps Mocha.
      flavor =
        if config.lmx.capabilities.theme.flavor == "system" then
          "mocha"
        else
          config.lmx.capabilities.theme.flavor;
    })
  ];
}
