{ pkgs, ... }:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.codex ];
}
