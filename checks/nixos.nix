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
