{
  nixpkgs,
  arch,
  system,
  modules,
  userName,
}:
let
  runtime = {
    name = "module-check";
    inherit arch;
    user = {
      name = userName;
      home = "/home/${userName}";
      uid = 1000;
      sudo = false;
    };
    ports = {
      tcp = [ ];
      udp = [ ];
    };
    modules = builtins.map toString modules;
  };
in
import (nixpkgs + "/nixos/lib/eval-config.nix") {
  inherit system;
  specialArgs = { inherit runtime; };
  modules = [
    (
      { config, ... }:
      {
        networking.hostName = runtime.name;
        # Each check evaluates a fresh system without persistent VM state.
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

        users.users.${runtime.user.name} = {
          isNormalUser = true;
          inherit (runtime.user) uid home;
        };
      }
    )
  ]
  ++ modules;
}
