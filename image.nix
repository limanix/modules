# Builds the base disk image for a new LimaNix virtual machine (VM).
#
# flake.nix loads this module together with platform.nix.
# platform.nix defines how the VM runs; this file creates its starting disk.
#
# This module creates:
# - An EFI boot partition with the label ESP and the files needed to boot.
# - A Btrfs root partition with the label nixos and the NixOS system files.
# - A compressed QCOW2 disk image for use by Lima.
#
# The partition labels and file systems match the settings in platform.nix.
# The disk also includes Nix store records for the first boot.
# A service loads these records into the Nix database before the Nix daemon starts.
# It sets the system profile and installs the boot loader for the running system.
# After setup, it removes the first-boot EFI image and the store records file.
# The service runs only while that records file exists.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
  inherit (config.system.boot.loader) ukiFile;
  nix = config.nix.package.out;
  registration = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };
in
{
  imports = [ (modulesPath + "/image/repart.nix") ];

  image.repart = {
    name = "limanix";
    partitions = {
      "10-esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${ukiFile}".source = "${config.system.build.uki}/${ukiFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "ESP";
          SizeMinBytes = "512M";
        };
      };
      "20-root" = {
        storePaths = [ config.system.build.toplevel ];
        contents."/nix-path-registration".source = "${registration}/registration";
        repartConfig = {
          Type = "root";
          Format = "btrfs";
          Label = "nixos";
          Minimize = "guess";
        };
      };
    };
  };

  system.build.qcow2 =
    pkgs.runCommand "limanix-${pkgs.stdenv.hostPlatform.system}.qcow2"
      { nativeBuildInputs = [ pkgs.qemu-utils ]; }
      ''
        qemu-img convert -f raw -O qcow2 -c \
          ${config.system.build.image}/${config.image.filePath} "$out"
      '';

  systemd.services.limanix-first-boot = {
    description = "Register the image's Nix store and install the boot loader";
    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/nix-path-registration";
      RequiresMountsFor = [ "/boot" ];
    };
    wantedBy = [ "sysinit.target" ];
    before = [
      "sysinit.target"
      "shutdown.target"
      "nix-daemon.socket"
      "nix-daemon.service"
    ];
    after = [ "local-fs.target" ];
    conflicts = [ "shutdown.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${nix}/bin/nix-store --load-db < /nix-path-registration
      touch /etc/NIXOS
      ${nix}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      /run/current-system/bin/switch-to-configuration boot
      rm -f /boot/EFI/Linux/${ukiFile} /nix-path-registration
    '';
  };
}
