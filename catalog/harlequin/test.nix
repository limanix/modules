{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  defaultConfiguration = helpers.evaluate [ ./default.nix ];
  package = import ./package.nix { inherit pkgs; };
in
{
  eval.defaults = helpers.verify "the module-owned adapter and theme package is installed" (
    helpers.installedAsDeclared defaultConfiguration package
    && import ./test/check.nix {
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs;
    }
  ) defaultConfiguration;
  run = import ./test/smoke.nix {
    profile = helpers.profileFor defaultConfiguration;
    inherit pkgs;
  };
  builds.harlequin = package;
}
