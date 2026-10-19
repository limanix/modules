{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  unstable = helpers.sourceFor configuration "unstable";
in
{
  eval.package = helpers.installed configuration unstable.packages.codex;
  run.commands = import ./test/commands.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
  };
}
