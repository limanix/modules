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

  config._module.args = {
    pinned = import ./lib/pinned.nix {
      sources = config.lmx.pins;
      inherit (pkgs.stdenv.hostPlatform) system;
      unfreePackages = config.nixpkgs.config.allowUnfreePackages or [ ];
    };
    # The catalog's nixos-unstable revision as { rev, sha256 }, for a platform that offers its
    # packages; it declares the pin itself before it reads pinned.
    unstableSource = builtins.fromTOML (builtins.readFile ./unstable.toml);
  };
}
