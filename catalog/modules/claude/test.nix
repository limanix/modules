{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  inherit (configuration) config;
  unstable = helpers.sourceFor configuration "unstable";
  installed = lib.findFirst (
    package: lib.getName package == "claude-code"
  ) null config.environment.systemPackages;
in
{
  eval = {
    package = installed != null && toString installed == toString unstable.packages.claude-code;
    unfreeDeclaration = builtins.elem "claude-code" config.nixpkgs.config.allowUnfreePackages;
    updatesDisabled = config.environment.sessionVariables.DISABLE_UPDATES == "1";
  };
  run.commands = import ./test/commands.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
    inherit (installed) version;
  };
  builds.artifact = installed;
}
