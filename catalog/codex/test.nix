{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
in
{
  eval.package = helpers.installed configuration pkgs.codex;
  run.commands = import ./test/commands.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
  };
}
