{
  config,
  lib,
  pkgs,
  pinned,
  ...
}:
let
  releases = (import ./releases.nix).versions;
  selected = lib.unique config.lmx.internal.rust.versions;
in
{
  imports = [ ./tool.nix ];

  options.lmx.internal.rust.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    internal = true;
    visible = false;
    description = "rust version lines selected by catalog modules.";
  };

  options.lmx.internal.rust.packages = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    internal = true;
    visible = false;
    description = "Selected rust package records for this evaluation.";
  };

  config = lib.mkMerge (
    map (
      version:
      lib.mkIf (builtins.elem version selected) (
        (import ./implementation.nix version) {
          inherit
            config
            lib
            pkgs
            pinned
            ;
        }
      )
    ) (builtins.attrNames releases)
  );
}
