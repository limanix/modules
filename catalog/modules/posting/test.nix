{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  latte = evaluate [
    ./default.nix
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
in
{
  eval = {
    defaults = verify "Posting is installed with Catppuccin Mocha by default" (import ./test/check.nix {
      inherit (defaultConfiguration) config;
      hasPackage = helpers.installed defaultConfiguration;
      inherit pkgs;
    }) defaultConfiguration;
    latte = verify "the Posting theme follows the guest's flavor" (
      latte.config.environment.variables.POSTING_THEME == "catppuccin-latte"
    ) latte;
  };
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaultConfiguration;
  };
}
