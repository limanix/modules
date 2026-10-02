{
  config,
  lib,
  pkgs,
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

  config = lib.mkMerge (
    map (
      version:
      lib.mkIf (builtins.elem version selected) (
        (import ./implementation.nix version) { inherit config lib pkgs; }
      )
    ) (builtins.attrNames releases)
  );
}
