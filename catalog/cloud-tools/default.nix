{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.awscli2
    pkgs.google-cloud-sdk
  ];
}
