{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify;
  defaultConfiguration = evaluate [ ./default.nix ];
  cases = import ./test/tests.nix {
    module.path = ./default.nix;
    inherit
      defaultConfiguration
      evaluate
      lib
      verify
      ;
  };
in
{
  eval = {
    defaults = verify "Tmux packages, navigation and session defaults" (import ./test/check.nix {
      inherit (defaultConfiguration) config;
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs;
    }) defaultConfiguration;
  }
  // cases.evaluation;
  run = import ./test/smoke.nix {
    inherit (defaultConfiguration) config;
    inherit (cases) configurations;
    inherit pkgs;
  };
  builds = lib.listToAttrs (
    map (plugin: {
      name = plugin.pluginName;
      value = plugin;
    }) (import ./plugins.nix { inherit pkgs; })
  );
}
