{ pkgs, ... }:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.gh ];
}
