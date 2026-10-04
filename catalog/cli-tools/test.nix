{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  overridden = helpers.evaluate [
    ./default.nix
    {
      programs.git.config.core.pager = "cat";
      programs.git.config.interactive.diffFilter = "cat";
    }
  ];
  settings = record: builtins.head record.config.programs.git.config;
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
        pkgs.btop
        pkgs.dust
        pkgs.duf
        pkgs.tealdeer
      ];
    gitDefaults =
      defaults.core.pager == "${pkgs.delta}/bin/delta"
      && defaults.interactive.diffFilter == "${pkgs.delta}/bin/delta --color-only";
    gitOverrides = userSettings.core.pager == "cat" && userSettings.interactive.diffFilter == "cat";
  };
  run = import ./test/run.nix {
    inherit pkgs;
    inherit (configuration) config;
    profile = helpers.profileFor configuration;
  };
}
