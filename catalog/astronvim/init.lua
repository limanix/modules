return function(paths)
  vim.opt.rtp:prepend(paths.lazy)
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")

  local specs = {
    {
      "AstroNvim/AstroNvim",
      dir = paths.astro,
      import = "astronvim.plugins",
      opts = { pin_plugins = false },
    },
  }
  -- Keep upstream plugin specifications and loading order, with Nix-owned sources.
  for repository, directory in pairs(paths.plugins) do
    table.insert(specs, { repository, dir = directory, optional = true, build = false })
  end
  vim.list_extend(specs, {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      dir = paths.catppuccin,
      lazy = false,
      priority = 1000,
      opts = { flavour = "mocha" },
    },
    { "AstroNvim/astroui", opts = { colorscheme = "catppuccin-mocha" } },
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        opts.treesitter.auto_install = false
        opts.treesitter.ensure_installed = {}
        local mappings = opts.mappings.n
        mappings["<M-h>"] = { function() require("smart-splits").resize_left(3) end, desc = "Resize left" }
        mappings["<M-j>"] = { function() require("smart-splits").resize_down(3) end, desc = "Resize down" }
        mappings["<M-k>"] = { function() require("smart-splits").resize_up(3) end, desc = "Resize up" }
        mappings["<M-l>"] = { function() require("smart-splits").resize_right(3) end, desc = "Resize right" }
      end,
    },
    {
      "AstroNvim/astrolsp",
      opts = function(_, opts)
        opts.servers = opts.servers or {}
        opts.config = opts.config or {}
        for server, configuration in pairs(paths.servers) do
          if not vim.tbl_contains(opts.servers, server) then table.insert(opts.servers, server) end
          opts.config[server] = vim.tbl_deep_extend("force", opts.config[server] or {}, configuration)
        end
      end,
    },
    { "nvim-treesitter/nvim-treesitter", opts = { install_dir = paths.parsers } },
    { "mrjones2014/smart-splits.nvim", lazy = false },
    { "nvim-mini/mini.icons", lazy = false, priority = 1000 },
    { "mason-org/mason.nvim", lazy = false, opts = { PATH = "append" } },
    -- Loading this installer refreshes its registry. Keep it behind explicit commands.
    {
      "mason-org/mason-lspconfig.nvim",
      event = function() return {} end,
      opts = { automatic_enable = false },
    },
    { "WhoIsSethDaniel/mason-tool-installer.nvim", opts = { run_on_start = false, ensure_installed = {} } },
    -- Nix supplies the native library; never download a binary during completion setup.
    { "saghen/blink.cmp", opts = { fuzzy = { implementation = "prefer_rust", prebuilt_binaries = { download = false } } } },
  })

  local config = vim.fn.stdpath("config")
  if vim.fn.isdirectory(config .. "/lua/plugins") == 1 or vim.fn.filereadable(config .. "/lua/plugins.lua") == 1 then
    table.insert(specs, { import = "plugins" })
  end

  require("lazy").setup(specs, {
    lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
    install = { missing = false },
    checker = { enabled = false },
    change_detection = { notify = false },
    rocks = { enabled = false },
  })

  local polish = config .. "/lua/polish.lua"
  if vim.fn.filereadable(polish) == 1 then dofile(polish) end
end
