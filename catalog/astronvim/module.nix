{
  config,
  pkgs,
  lib,
  ...
}:
let
  releases = import ./releases.nix;
  selected = config.lmx.internal.astronvim.versions;
in
{
  imports = [
    ../neovim/default.nix
    ../lazygit/default.nix
  ];

  options.lmx.internal.astronvim.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    apply = lib.unique;
    internal = true;
    visible = false;
    description = "AstroNvim version lines selected by catalog modules.";
  };

  config = lib.mkMerge (
    [
      {
        assertions = [
          {
            assertion = builtins.length selected == 1;
            message = "astronvim: select one line";
          }
        ];
      }
    ]
    ++ map (
      version:
      lib.mkIf (builtins.length selected == 1 && builtins.elem version selected) (
        (import ./implementation.nix version) { inherit config pkgs lib; }
      )
    ) (builtins.attrNames releases)
  );
}
