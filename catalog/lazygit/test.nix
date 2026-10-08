{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  latte = evaluate [
    ./default.nix
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
in
{
  eval = {
    defaults = verify "Lazygit, Git and the complete managed palette of the theme are declared" (import
      ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
      }
    ) defaultConfiguration;
    latte = verify "the managed colors follow the guest's flavor" (import ./test/check.nix {
      inherit (latte) config;
      hasPackage = helpers.installed latte;
    }) latte;
  }
  // (import ./test/tests.nix { inherit defaultConfiguration evaluate verify; });
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaultConfiguration;
  };
}
