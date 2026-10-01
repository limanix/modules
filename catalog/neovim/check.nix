{ config, hasPackage, ... }:
config.programs.neovim.enable && hasPackage config.programs.neovim.finalPackage
