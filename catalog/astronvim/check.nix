{ config, version, ... }:
config.programs.neovim.enable
&& (version == null || config.lmx.internal.astronvim.version == version)
&& config.programs.neovim.defaultEditor
&& config.programs.nix-ld.enable
&& config.programs.neovim.configure ? customLuaRC
