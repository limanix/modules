{
  config,
  pkgs,
  hasPackage,
  ...
}:
config.programs.git.enable && hasPackage pkgs.lazygit
