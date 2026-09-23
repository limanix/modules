{
  nixpkgs,
  arch,
  system,
  modules,
}:
let
  runtime = {
    name = "module-check";
    inherit arch;
    user = {
      name = "dev";
      home = "/home/dev";
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
    {
      networking.hostName = runtime.name;
      system.stateVersion = "26.05";

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
  ]
  ++ modules;
}
