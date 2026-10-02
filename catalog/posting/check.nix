{
  config,
  pkgs,
  hasPackage,
  ...
}:
hasPackage pkgs.posting && config.environment.variables.POSTING_THEME == "catppuccin-mocha"
