# Guest platform shared by base images and VM rebuilds.
{
  config,
  lib,
  pkgs,
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

  # Labels and formats must match image.nix.
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
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Keep NixOS-declared keys accessible alongside Lima's keys.
  systemd.tmpfiles.rules = [ "d /etc/ssh/authorized_keys.d 0755 root root -" ];
  environment.systemPackages = [
    # Apple's virtiofs rejects mode-0 symlink placeholders; create them as 0600.
    (lib.hiPrio (
      pkgs.gnutar.overrideAttrs (previous: {
        postPatch = previous.postPatch or "" + ''
          substituteInPlace src/extract.c \
            --replace-fail "O_WRONLY | O_CREAT | O_EXCL, 0)" "O_WRONLY | O_CREAT | O_EXCL, S_IRUSR | S_IWUSR)"
        '';
      })
    ))
  ];
  programs.nix-ld = {
    enable = lib.mkDefault true;
    libraries = with pkgs; [
      freetype
      libx11
      libxext
      libxi
      libxrender
      libxtst
    ];
  };
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
