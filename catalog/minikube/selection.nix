{
  config,
  lib,
  pkgs,
  pinned,
  ...
}:
let
  releases = (import ./releases.nix).versions;
  selected = lib.unique config.lmx.internal.minikube.versions;
in
{
  imports = [ ../k9s/default.nix ];

  options.lmx.internal.minikube.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    internal = true;
    visible = false;
    description = "minikube version lines selected by catalog modules.";
  };

  options.lmx.internal.minikube.packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    internal = true;
    visible = false;
    description = "Resolved packages for the selected minikube lines.";
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
