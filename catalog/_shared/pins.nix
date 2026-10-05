# Infrastructure for module-declared Nixpkgs sources; no source is registered here.
# Identity: the revision supplied by a selected module.
# Declaration: ordinary constant hashes; no mkDefault, mkOverride or mkForce
# around the registry, entries or enclosing definitions.
# Merge: equal ordinary hash declarations at the same revision agree.
# Conflict: different ordinary hashes fail the standard string merge.
# NixOS priority handling is unchanged; priority wrappers violate the contract.
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
