{
  config,
  hasPackage,
  ...
}:
config.programs.git.enable
&& config.programs.lazygit.enable
&& hasPackage config.programs.lazygit.package
