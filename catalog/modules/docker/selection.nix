{
  config,
  lib,
  pkgs,
  pinned,
  ...
}:
let
  releases = import ./releases.nix;
  selected = lib.unique config.lmx.internal.docker.versions;
in
{
  imports = [ ./help.nix ];

  options.lmx.internal.docker.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    internal = true;
    visible = false;
    description = "docker version lines selected by catalog modules.";
  };

  options.lmx.internal.docker.packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    internal = true;
    visible = false;
    description = "Resolved packages for the selected docker lines.";
  };

  config = lib.mkMerge (
    [
      {
        assertions = [
          {
            assertion = builtins.length selected == 1;
            message = "docker: select one line";
          }
        ];
        # A terminal interface to the containers, logs, images and volumes of the engine.
        environment.systemPackages = [ pkgs.lazydocker ];
      }
    ]
    ++ map (
      version:
      lib.mkIf (builtins.length selected == 1 && builtins.elem version selected) (
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
