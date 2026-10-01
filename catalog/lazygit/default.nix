{ pkgs, ... }:
{
  imports = [ ../git/default.nix ];

  environment.systemPackages = [ pkgs.lazygit ];
}
