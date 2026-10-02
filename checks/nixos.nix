{
  nixpkgs,
  system,
  modules,
  userName,
}:
let
  shared = import ./shared-files.nix;
in
import (nixpkgs + "/nixos/lib/eval-config.nix") {
  inherit system;
  modules = [
    ../interface.nix
    (
      { lib, ... }:
      let
        priority =
          package:
          if builtins.isAttrs package then
            package.meta.priority or lib.meta.defaultPriority
          else
            lib.meta.defaultPriority;
      in
      {
        # Match the platform base: profile inputs do not depend on import order.
        # Contextual strings and __toString objects are valid package values.
        options.environment.systemPackages = lib.mkOption {
          apply = lib.sort (
            left: right:
            if toString left == toString right then
              priority left < priority right
            else
              toString left < toString right
          );
        };
      }
    )
    (
      { config, ... }:
      {
        limanix.user = {
          name = userName;
          home = "/home/${userName}";
        };
        networking.hostName = "module-check";
        system.stateVersion = config.system.nixos.release;

        boot.loader.grub = {
          device = "nodev";
          efiSupport = true;
          efiInstallAsRemovable = true;
        };
        fileSystems = {
          "/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };
          "/boot" = {
            device = "/dev/vda1";
            fsType = "vfat";
          };
        };

        users.users.${config.limanix.user.name} = {
          isNormalUser = true;
          uid = 1000;
          inherit (config.limanix.user) home shell;
        };
      }
    )
  ]
  ++ shared.public
  ++ modules;
}
