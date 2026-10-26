{ config, pkgs, ... }:
{
  imports = [
    ../../toolchains/java/default.nix
    ./help.nix
  ];

  environment.systemPackages = [
    (pkgs.quarkus.override { jdk = config.lmx.capabilities.jdk.package; })
  ];
}
