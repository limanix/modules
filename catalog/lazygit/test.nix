{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
in
{
  eval = {
    defaults = verify "Lazygit, Git and the complete managed Mocha palette are declared" (import
      ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
      }
    ) defaultConfiguration;
  }
  // (import ./test/tests.nix { inherit defaultConfiguration evaluate verify; });
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaultConfiguration;
  };
}
