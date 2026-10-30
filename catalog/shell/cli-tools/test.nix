{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  overridden = helpers.evaluate [
    ./default.nix
    {
      programs.git.config.core.pager = "cat";
      programs.git.config.interactive.diffFilter = "cat";
    }
  ];
  themed = helpers.evaluate [
    ./default.nix
    { lmx.capabilities.theme.name = "kanagawa-wave"; }
  ];
  settings = record: builtins.head record.config.programs.git.config;
  btop = lib.findFirst (
    package: (package.pname or "") == "btop"
  ) null configuration.config.environment.systemPackages;
  defaults = settings configuration;
  userSettings = settings overridden;
in
{
  eval = {
    packages =
      configuration.config.programs.git.enable
      && builtins.all (helpers.installed configuration) [
        pkgs.ripgrep
        pkgs.fd
        pkgs.fzf
        pkgs.bat
        pkgs.eza
        pkgs.delta
        pkgs.jq
        pkgs.yq-go
        pkgs.xh
        pkgs.dust
        pkgs.duf
        pkgs.tealdeer
      ]
      && btop != null;
    gitDefaults =
      defaults.core.pager == "${pkgs.delta}/bin/delta"
      && defaults.interactive.diffFilter == "${pkgs.delta}/bin/delta --color-only";
    gitOverrides = userSettings.core.pager == "cat" && userSettings.interactive.diffFilter == "cat";
    themeColors =
      let
        variables = themed.config.environment.variables;
        themedSettings = settings themed;
      in
      configuration.config.environment.variables.BAT_THEME == "ansi"
      && !(configuration.config.environment.variables ? BAT_CACHE_PATH)
      && variables.BAT_THEME == "limanix"
      && lib.hasPrefix builtins.storeDir variables.BAT_CACHE_PATH
      && themedSettings.core.pager != defaults.core.pager
      && themedSettings.delta.plus-style == "syntax #2b2f2f";
  };
  run = import ./test/run.nix {
    inherit pkgs;
    inherit (configuration) config;
    profile = helpers.profileFor configuration;
  };
  builds.btop = btop;
}
