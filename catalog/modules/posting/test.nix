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
    { lmx.capabilities.theme.name = "nord"; }
  ];
  posting =
    configuration:
    lib.findFirst (
      package: (package.pname or "") == "posting"
    ) null configuration.config.environment.systemPackages;
in
{
  eval = {
    defaults = verify "Posting is installed with the guest's theme" (import ./test/check.nix {
      inherit (defaultConfiguration) config;
    }) defaultConfiguration;
    themed =
      verify "the Posting theme follows the guest's theme"
        (lib.hasInfix themed.config.lmx.capabilities.theme.palette.accent (posting themed).postPatch)
        themed;
  };
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaultConfiguration;
  };
  builds.posting = posting defaultConfiguration;
}
