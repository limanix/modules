{ config, lib, ... }:
{
  imports = [ ./help.nix ];

  programs.starship = {
    enable = true;
    settings =
      lib.recursiveUpdate
        (import ./settings.nix {
          inherit lib;
          inherit (config.lmx.capabilities) theme;
        })
        {
          hostname.ssh_only = lib.mkDefault false;
          status.disabled = lib.mkDefault false;
        };
  };
}
