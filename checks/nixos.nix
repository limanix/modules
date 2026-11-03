# Evaluate catalog modules with the shared test platform.
# Boot settings complete the configuration; this does not start a VM.
{
  nixpkgs,
  system,
  modules,
  userName,
}:
let
  evaluated = import (nixpkgs + "/nixos/lib/eval-config.nix") {
    inherit system;
    modules = [
      (import ../catalog/_shared/test/platform.nix { inherit userName; })
      {
        networking.hostName = "module-check";
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
      }
    ]
    ++ modules;
  };
in
{
  inherit (evaluated)
    config
    pkgs
    options
    graph
    ;
  inherit (evaluated.pkgs) lib;
}
