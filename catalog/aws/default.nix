{ pkgs, ... }:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.awscli2 ];
}
