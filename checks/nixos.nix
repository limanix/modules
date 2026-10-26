# Create a NixOS evaluation environment for catalog checks.
#
# The caller supplies Nixpkgs, the target system, modules, and a test user name.
# catalog/_shared/test/platform.nix provides the shared test settings.
# Minimal boot and file system settings allow a complete system to be evaluated.
# The result includes its configuration, options, packages, and import graph.
# This file does not boot a VM or build a disk image.
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
