{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  overridden = evaluate [
    ./default.nix
    { environment.variables.POSTING_THEME = "galaxy"; }
  ];
in
{
  eval = {
    defaults = verify "Posting is installed with its Mocha environment default" (import ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
        inherit pkgs;
      }
    ) defaultConfiguration;
    themeOverride = verify "the Posting environment theme accepts an ordinary assignment" (
      overridden.config.environment.variables.POSTING_THEME == "galaxy"
      && helpers.installed overridden pkgs.posting
    ) overridden;
  };
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    inherit (defaultConfiguration) config;
    profile = profileFor defaultConfiguration;
  };
}
