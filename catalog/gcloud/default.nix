{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.google-cloud-sdk ];
}
