{
  config,
  lib,
  pkgs,
  pinned,
  ...
}:
let
  releases = (import ./releases.nix).versions;
  selected = lib.unique config.lmx.internal.helm.versions;
in
{
  imports = [ ./help.nix ];

  options.lmx.internal.helm.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    internal = true;
    visible = false;
    description = "helm version lines selected by catalog modules.";
  };

  options.lmx.internal.helm.packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    internal = true;
    visible = false;
    description = "Resolved packages for the selected helm lines.";
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
