{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  cases = import ./test/tests.nix {
    module.path = ./default.nix;
    userName = defaultConfiguration.config.limanix.user.name;
    inherit
      defaultConfiguration
      evaluate
      lib
      pkgs
      verify
      ;
  };
  smoke =
    name: configuration:
    import ./test/smoke.nix {
      inherit (configuration) config;
      profile = profileFor configuration;
      inherit name pkgs lib;
    };
in
{
  eval = {
    defaults = verify "Zsh login shell, no managed prompt, tools and local-history defaults" (import
      ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
        inherit pkgs lib;
      }
    ) defaultConfiguration;
  }
  // cases.evaluation;
  run.startup = smoke "default" defaultConfiguration;
}
