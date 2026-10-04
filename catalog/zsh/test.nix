{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  cases = import ./test/tests.nix {
    module.path = ./default.nix;
    userName = defaultConfiguration.config.limanix.user.name;
    inherit
      defaultConfiguration
      evaluate
      pkgs
      verify
      ;
  };
in
{
  eval = {
    defaults = verify "Zsh login shell, tools and local-history defaults" (import ./test/check.nix {
      inherit (defaultConfiguration) config;
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs;
    }) defaultConfiguration;
  }
  // cases.evaluation;
  fails = { };
  run = import ./test/smoke.nix {
    inherit (defaultConfiguration) config;
    profile = profileFor defaultConfiguration;
    inherit pkgs lib;
  };
  builds = { };
  vm.activation = import ./test/vm.nix {
    inherit (defaultConfiguration) config;
    inherit pkgs lib;
  };
}
