{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  native = (import ./colorschemes.nix pkgs).${theme.name} or null;
  flavour = if theme.dark then "mocha" else "latte";
  colorscheme =
    if native == null then
      ''
        require("catppuccin").setup({
          flavour = "${flavour}",
          color_overrides = {
            ${flavour} = vim.json.decode([==[${builtins.toJSON (import ../../_shared/lib/catppuccin.nix theme.palette)}]==]),
          },
        })
        vim.cmd.colorscheme("catppuccin-${flavour}")
      ''
    else
      ''
        vim.cmd.colorscheme("${native.colorscheme}")
      '';
in
{
  imports = [ ./help.nix ];

  options.lmx.internal.neovim.colorscheme = lib.mkOption {
    type = lib.types.bool;
    default = true;
    internal = true;
    visible = false;
    description = "Whether plain Neovim draws the guest's theme; an editor setup with its own colorscheme turns it off.";
  };

  config.programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # The wrapper starts this script through VIMINIT, so it loads the personal init file itself.
    configure = lib.mkIf (config.lmx.internal.neovim.colorscheme && theme.name != "system") {
      packages.limanix.start = [
        (if native == null then pkgs.vimPlugins.catppuccin-nvim else native.plugin)
      ];
      customLuaRC = ''
        vim.o.background = "${if theme.dark then "dark" else "light"}"
        ${colorscheme}
        local config = vim.fn.stdpath("config")
        if vim.fn.filereadable(config .. "/init.lua") == 1 then
          vim.env.MYVIMRC = config .. "/init.lua"
          dofile(vim.env.MYVIMRC)
        elseif vim.fn.filereadable(config .. "/init.vim") == 1 then
          vim.env.MYVIMRC = config .. "/init.vim"
          vim.cmd.source(vim.fn.fnameescape(vim.env.MYVIMRC))
        end
      '';
    };
  };
}
