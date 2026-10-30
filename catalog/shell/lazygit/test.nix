{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify profileFor;
  defaultConfiguration = evaluate [ ./default.nix ];
  themed = evaluate [
    ./default.nix
    { lmx.capabilities.theme.name = "gruvbox-dark"; }
  ];
in
{
  eval = {
    defaults = verify "Lazygit and Git are declared, in Lazygit's own terminal colors with system" (
      import
      ./test/check.nix
      {
        inherit (defaultConfiguration) config;
        hasPackage = helpers.installed defaultConfiguration;
      }
    ) defaultConfiguration;
    themed = verify "the managed colors follow the guest's theme" (import ./test/check.nix {
      inherit (themed) config;
      hasPackage = helpers.installed themed;
    }) themed;
    clipboard = verify "copies go to the Mac clipboard through the platform's pbcopy" (
      defaultConfiguration.config.programs.lazygit.settings.os.copyToClipboardCmd
      == "printf %s {{text}} | pbcopy"
    ) defaultConfiguration;
  };
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaultConfiguration;
  };
}
