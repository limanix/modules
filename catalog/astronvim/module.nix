{
  config,
  pkgs,
  lib,
  ...
}:
let
  packages = import ./packages.nix {
    inherit pkgs lib;
    inherit (config.lmx.internal.astronvim) version;
    parsers = lib.unique (
      lib.concatMap (language: language.parsers) (
        builtins.attrValues config.lmx.capabilities.languageSupport.languages
      )
    );
  };
  # Lazy identifies require-triggered plugins by their directory basename.
  # Keep plugin IDs in these paths while retaining immutable Nix package sources.
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
        lib.nameValuePair
          (
            {
              rust-analyzer = "rust_analyzer";
              typescript-language-server = "ts_ls";
            }
            .${identity} or identity
          )
          {
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
  imports = [
    ../neovim/default.nix
    ../lazygit/default.nix
  ];

  options.lmx.internal.astronvim.version = lib.mkOption {
    type = lib.types.enum (builtins.attrNames (import ./releases.nix));
    internal = true;
    visible = false;
    description = "Single AstroNvim version line selected by catalog modules.";
  };

  config = {
    environment.systemPackages = lib.mkBefore (
      with pkgs;
      [
        ripgrep
        fd
        tree-sitter
        curl
        unzip
      ]
    );

    programs = {
      # Mason may install foreign Linux binaries. Language modules remain preferred.
      nix-ld.enable = lib.mkDefault true;
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
            setup(paths)
          end
        '';
      };
    };
  };
}
