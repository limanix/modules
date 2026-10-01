{ config, hasPackage, ... }:
config.programs.git.enable && hasPackage config.programs.git.package
