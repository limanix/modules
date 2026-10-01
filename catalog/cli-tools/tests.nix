{
  module,
  defaultConfiguration,
  evaluate,
  pkgs,
  componentChecks,
  verify,
  ...
}:
let
  overridden = evaluate [
    module.path
    {
      programs.git.config.core.pager = "cat";
      programs.git.config.interactive.diffFilter = "cat";
    }
  ];
  settings = builtins.head overridden.config.programs.git.config;
  defaults = builtins.head defaultConfiguration.config.programs.git.config;
in
{
  evaluation = {
    composition = componentChecks;
    gitPreferences = verify "Git pager and diff-filter ordinary overrides" (
      defaults.core.pager == "${pkgs.delta}/bin/delta"
      && defaults.interactive.diffFilter == "${pkgs.delta}/bin/delta --color-only"
      && settings.core.pager == "cat"
      && settings.interactive.diffFilter == "cat"
    ) overridden;
  };
}
