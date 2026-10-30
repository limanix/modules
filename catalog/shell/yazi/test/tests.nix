{
  module,
  defaultConfiguration,
  evaluate,
  pkgs,
  verify,
  ...
}:
let
  managedOverride = evaluate [
    module.path
    {
      programs.yazi.settings.theme.mgr.cwd.fg = "#123456";
    }
  ];
  managedFlavor = evaluate [
    module.path
    {
      programs.yazi = {
        settings.theme.flavor = {
          dark = "fixture";
          light = "fixture";
        };
        flavors.fixture = pkgs.writeTextDir "flavor.toml" ''
          [mgr]
          cwd = { fg = "#abcdef" }
        '';
      };
    }
  ];
  solarized = evaluate [
    module.path
    { lmx.capabilities.theme.name = "solarized-light"; }
  ];
in
{
  configurations = { inherit managedOverride managedFlavor solarized; };
  evaluation = {
    independentShell = verify "Yazi provides shell integration without enabling Zsh" (
      !defaultConfiguration.config.programs.zsh.enable
    ) defaultConfiguration;
  };
}
