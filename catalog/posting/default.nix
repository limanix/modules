{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.posting ];
  environment.variables.POSTING_THEME = lib.mkDefault "catppuccin-mocha";
}
