{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.curl
    pkgs.jq
    pkgs.ripgrep
  ];
}
