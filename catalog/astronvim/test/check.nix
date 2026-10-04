{ config, hasPackage }:
config.programs.neovim.enable
&& config.programs.neovim.defaultEditor
&& config.programs.nix-ld.enable
&& config.programs.neovim.configure ? customLuaRC
&& hasPackage config.programs.neovim.finalPackage
&& hasPackage config.programs.lazygit.package
&& hasPackage config.programs.git.package
