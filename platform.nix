# Base NixOS settings for a LimaNix virtual machine (VM).
#
# flake.nix uses this module to build the base disk.
# The client uses it again when it rebuilds the system inside a VM.
# Both use one set of settings to boot the system and mount its disk.
#
# This module sets:
# - VM support, the EFI boot loader, and automatic disk growth.
# - The root and boot file systems, with the disk labels from image.nix.
# - Lima and SSH services for access from the host computer.
# - User accounts that can change outside the Nix configuration.
# - Sudo without a password and trusted Nix access for the wheel group.
# - Support for the new Nix commands and flakes.
# - A default stateVersion based on the NixOS release.
#
# image.nix creates the disk; this file tells NixOS how to use it.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    growPartition = true;
    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
    kernelParams = [ "console=tty0" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "discard=async"
        "x-systemd.growfs"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  services.lima.enable = true;
  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = true;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  system.stateVersion = lib.mkDefault config.system.nixos.release;
}
