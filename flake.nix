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
