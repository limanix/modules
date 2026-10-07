{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.posting ];
  environment.variables.POSTING_THEME = lib.mkDefault "catppuccin-${config.lmx.capabilities.theme.flavor}";
}
