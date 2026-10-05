{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.lmx.pins = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Nixpkgs revisions and content hashes declared by selected modules.";
  };

  config._module.args.pinned = import ./lib/pinned.nix {
    sources = config.lmx.pins;
    inherit (pkgs.stdenv.hostPlatform) system;
    unfreePackages = config.nixpkgs.config.allowUnfreePackages or [ ];
  };
}
