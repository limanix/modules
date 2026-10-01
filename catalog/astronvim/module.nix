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
        builtins.attrValues config.lmx.capabilities.editor.languages
      )
    );
  };
  paths = pkgs.writeText "astronvim-plugins.json" (
    builtins.toJSON {
      astro = toString packages.astro;
      lazy = toString pkgs.vimPlugins.lazy-nvim;
      parsers = toString packages.parserDirectory;
      servers = lib.mapAttrs' (
        identity: tool:
        lib.nameValuePair (if identity == "rust-analyzer" then "rust_analyzer" else identity) {
          cmd = [ tool.command ] ++ tool.args;
        }
      ) config.lmx.capabilities.editor.tools;
      plugins = lib.mapAttrs (_: toString) packages.plugins;
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
