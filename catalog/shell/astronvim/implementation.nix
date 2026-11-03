version:
{
  config,
  pkgs,
  lib,
}:
let
  inherit (config.lmx.capabilities) theme;
  serverName = import ./server-name.nix;
  native = (import ../neovim/colorschemes.nix pkgs).${theme.name} or null;
  themeSettings = {
    inherit (theme) name dark;
    catppuccin = import ../../_shared/lib/catppuccin.nix theme.palette;
  }
  // lib.optionalAttrs (native != null) {
    inherit (native) colorscheme;
    plugin = "${pluginSources}/theme";
  };
  packages = import ./packages.nix {
    inherit pkgs lib version;
    parsers = lib.unique (
      lib.concatMap (language: language.parsers) (
        builtins.attrValues config.lmx.capabilities.languageSupport.languages
      )
    );
  };
  sourceEntries = [
    {
      name = "AstroNvim";
      path = packages.astro;
    }
    {
      name = "catppuccin";
      path = pkgs.vimPlugins.catppuccin-nvim;
    }
  ]
  ++ lib.mapAttrsToList (repository: package: {
    name = builtins.baseNameOf repository;
    path = package;
  }) packages.plugins
  ++ lib.optional (!(packages.plugins ? "folke/lazy.nvim")) {
    name = "lazy.nvim";
    path = pkgs.vimPlugins.lazy-nvim;
  }
  ++ lib.optional (native != null) {
    name = "theme";
    path = native.plugin;
  };
  sourceNames = map (entry: entry.name) sourceEntries;
  pluginSources =
    assert lib.assertMsg (
      builtins.length sourceNames == builtins.length (lib.unique sourceNames)
    ) "AstroNvim plugin IDs must have unique source directories";
    pkgs.linkFarm "astronvim-plugin-sources" sourceEntries;
  paths = pkgs.writeText "astronvim-plugins.json" (
    builtins.toJSON {
      astro = "${pluginSources}/AstroNvim";
      lazy = "${pluginSources}/lazy.nvim";
      parsers = toString packages.parserDirectory;
      catppuccin = "${pluginSources}/catppuccin";
      servers = lib.mapAttrs' (
        identity: tool:
        lib.nameValuePair (serverName identity) {
          cmd = [ tool.command ] ++ tool.args;
        }
      ) config.lmx.capabilities.languageSupport.tools;
      plugins = lib.mapAttrs (
        repository: _: "${pluginSources}/${builtins.baseNameOf repository}"
      ) packages.plugins;
    }
  );
in
{
  environment.systemPackages = lib.mkBefore (
    with pkgs;
    [
      ripgrep
      fd
      # :TSInstall downloads with curl and compiles with tree-sitter and a C compiler.
      tree-sitter
      gcc
      curl
      unzip
    ]
  );

  programs = {
    neovim = {
      defaultEditor = lib.mkDefault true;
      configure.customLuaRC = ''
        local config = vim.fn.stdpath("config")
        if vim.fn.filereadable(config .. "/init.lua") == 1 then
          dofile(config .. "/init.lua")
        elseif vim.fn.filereadable(config .. "/init.vim") == 1 then
          vim.cmd.source(vim.fn.fnameescape(config .. "/init.vim"))
        else
          local paths = vim.json.decode(table.concat(vim.fn.readfile("${paths}"), "\n"))
          local setup = dofile("${./init.lua}")
          setup(paths, vim.json.decode([==[${builtins.toJSON themeSettings}]==]))
        end
      '';
    };
  };
}
