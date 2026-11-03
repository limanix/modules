{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  defaultConfiguration = helpers.evaluate [ ./default.nix ];
  themed = helpers.evaluate [
    ./default.nix
    { lmx.capabilities.theme.name = "dracula"; }
  ];
  inherit (defaultConfiguration.config.lmx.capabilities) theme;
  package =
    configuration:
    import ./package.nix {
      inherit pkgs;
      inherit (configuration.config.lmx.capabilities) theme;
    };
in
{
  eval.defaults = helpers.verify "the module-owned adapter and theme package is installed" (
    helpers.installedAsDeclared defaultConfiguration (package defaultConfiguration)
    && import ./test/check.nix {
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs theme;
    }
  ) defaultConfiguration;
  eval.themed =
    helpers.verify "the default theme follows the guest's theme"
      (helpers.installedAsDeclared themed (package themed))
      themed;
  run = import ./test/smoke.nix {
    profile = helpers.profileFor defaultConfiguration;
    inherit pkgs theme;
  };
  builds.harlequin = package defaultConfiguration;
}
