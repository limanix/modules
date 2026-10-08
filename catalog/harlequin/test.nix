{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  defaultConfiguration = helpers.evaluate [ ./default.nix ];
  latte = helpers.evaluate [
    ./default.nix
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
  package =
    flavor:
    import ./package.nix {
      inherit pkgs flavor;
    };
in
{
  eval.defaults = helpers.verify "the module-owned adapter and theme package is installed" (
    helpers.installedAsDeclared defaultConfiguration (package "mocha")
    && import ./test/check.nix {
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs;
    }
  ) defaultConfiguration;
  eval.latte =
    helpers.verify "the default theme follows the guest's flavor"
      (helpers.installedAsDeclared latte (package "latte"))
      latte;
  run = import ./test/smoke.nix {
    profile = helpers.profileFor defaultConfiguration;
    inherit pkgs;
  };
  builds.harlequin = package "mocha";
}
