{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  # Whether `yazi` is the wrapper that adds the store-backed theme.
  themed =
    configuration:
    lib.hasInfix "yazi-with-default-theme" (
      configuration.config.programs.yazi.package.drvAttrs.buildCommand or ""
    );
  # The store-backed theme and its wrapper exist with a Catppuccin flavor.
  mochaConfiguration = evaluate [
    ./default.nix
    { lmx.capabilities.theme.flavor = "mocha"; }
  ];
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
    systemTheme = verify "the system flavor runs Yazi with its own presets in the terminal's colors" (
      !themed defaultConfiguration && themed mochaConfiguration
    ) defaultConfiguration;
  }
  // cases.evaluation;
  fails = { };
  run = import ./test/smoke.nix {
    inherit (defaultConfiguration) config;
    profile = profileFor mochaConfiguration;
    systemProfile = profileFor defaultConfiguration;
    inherit (cases) configurations;
    inherit pkgs profileFor;
  };
  builds = { };
}
