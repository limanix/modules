{ config, pkgs, ... }:
{
  environment.systemPackages = [
    (import ./package.nix {
      inherit pkgs;
      inherit (config.lmx.capabilities.theme) flavor;
    })
  ];
}
