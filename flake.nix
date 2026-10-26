# Nix entry point for building the LimaNix base disk.
#
# The inputs select a NixOS release and the nixos-lima module.
# flake.lock records the exact source versions used for the build.
# nixos-lima uses the same Nixpkgs input as the rest of the system.
#
# This file defines a build for aarch64-linux and x86_64-linux.
# Each build combines:
# - nixos-lima: support for running NixOS in Lima.
# - platform.nix: boot, disk, and basic VM settings.
# - image.nix: disk creation and first-boot setup.
#
# The result is a QCOW2 disk image at packages.<system>.image.
# The release build uses this output to prepare the disk for download.
{
  description = "LimaNix catalog base";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-lima = {
      url = "github:nixos-lima/nixos-lima/v0.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nixos-lima, ... }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      image =
        system:
        nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            nixos-lima.nixosModules.lima
            ./platform.nix
            ./image.nix
          ];
        };
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system: {
        image = (image system).config.system.build.qcow2;
      });
    };
}
