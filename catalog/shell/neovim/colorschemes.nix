pkgs: {
  catppuccin-mocha = {
    plugin = pkgs.vimPlugins.catppuccin-nvim;
    colorscheme = "catppuccin-mocha";
    transparent = {
      module = "catppuccin";
      options.transparent_background = true;
    };
  };
  tokyo-night = {
    plugin = pkgs.vimPlugins.tokyonight-nvim;
    colorscheme = "tokyonight-night";
    transparent = {
      module = "tokyonight";
      options = {
        transparent = true;
        styles = {
          sidebars = "transparent";
          floats = "transparent";
        };
      };
    };
  };
  dracula = {
    plugin = pkgs.vimPlugins.dracula-nvim;
    colorscheme = "dracula";
    transparent = {
      module = "dracula";
      options.transparent_bg = true;
    };
  };
  nord = {
    plugin = pkgs.vimPlugins.nord-nvim;
    colorscheme = "nord";
    transparent.globals.nord_disable_background = true;
  };
  gruvbox-dark = {
    plugin = pkgs.vimPlugins.gruvbox-nvim;
    colorscheme = "gruvbox";
    transparent = {
      module = "gruvbox";
      options.transparent_mode = true;
    };
  };
  rose-pine = {
    plugin = pkgs.vimPlugins.rose-pine;
    colorscheme = "rose-pine-main";
    transparent = {
      module = "rose-pine";
      options.styles.transparency = true;
    };
  };
  kanagawa-wave = {
    plugin = pkgs.vimPlugins.kanagawa-nvim;
    colorscheme = "kanagawa-wave";
    transparent = {
      module = "kanagawa";
      options.transparent = true;
    };
  };
  everforest-dark = {
    plugin = pkgs.vimPlugins.everforest;
    colorscheme = "everforest";
    transparent.globals.everforest_transparent_background = 1;
  };
  solarized-light = {
    plugin = pkgs.vimPlugins.nvim-solarized-lua;
    colorscheme = "solarized";
    transparent.globals.solarized_termtrans = 1;
  };
  github-light = {
    plugin = pkgs.vimPlugins.github-nvim-theme;
    colorscheme = "github_light_default";
    transparent = {
      module = "github-theme";
      options.options.transparent = true;
    };
  };
}
