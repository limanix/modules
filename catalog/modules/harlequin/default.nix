{ config, pkgs, ... }:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [
    # Harlequin refuses Textual's terminal theme, so the system theme draws the palette's colors.
    (import ./package.nix {
      inherit pkgs;
      inherit (config.lmx.capabilities) theme;
    })
  ];
}
