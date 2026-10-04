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
    installed = verify "Yazi and its configured preview dependencies are installed" (import
      ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
      }
    ) defaultConfiguration;
  }
  // cases.evaluation;
  fails = { };
  run = import ./test/smoke.nix {
    inherit (defaultConfiguration) config;
    profile = profileFor defaultConfiguration;
    inherit (cases) configurations;
    inherit pkgs profileFor;
  };
  builds = { };
}
