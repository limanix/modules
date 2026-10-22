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
      programs.yazi.settings = {
        yazi.mgr.show_hidden = true;
        theme.mgr.cwd.fg = "#123456";
      };
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
  latte = evaluate [
    module.path
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
  packageOverride = evaluate [
    module.path
    { programs.yazi.package = pkgs.yazi; }
  ];
in
{
  configurations = { inherit managedOverride managedFlavor latte; };
  evaluation = {
    independentShell = verify "Yazi provides shell integration without enabling Zsh" (
      !defaultConfiguration.config.programs.zsh.enable
    ) defaultConfiguration;
    managedOverride = verify "standard managed Yazi settings remain available" (
      managedOverride.config.programs.yazi.settings.yazi.mgr.show_hidden
      && managedOverride.config.programs.yazi.settings.theme.mgr.cwd.fg == "#123456"
    ) managedOverride;
    managedFlavor = verify "managed flavors retain their native precedence" (
      managedFlavor.config.programs.yazi.settings.theme.flavor.dark == "fixture"
      && managedFlavor.config.programs.yazi.settings.theme.flavor.light == "fixture"
    ) managedFlavor;
    packageOverride = verify "the default Yazi package accepts an ordinary override" (
      packageOverride.config.programs.yazi.package.outPath == pkgs.yazi.outPath
    ) packageOverride;
  };
}
