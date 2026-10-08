-- nvim-treesitter counts only parsers in its install_dir as installed, AstroNvim
-- enables only installed languages, and :TSInstall writes into that directory.
-- Keep it writable and link the catalog's parsers and queries into it. Links into
-- an earlier catalog build are replaced or removed; :TSInstall parsers stay.
local function link_parsers(source, install_dir, treesitter)
  local uv = vim.uv
  local function catalog_link(path)
    local target = uv.fs_readlink(path)
    return target ~= nil and target:find("-astronvim-parsers/", 1, true) ~= nil
  end
  local function revision_file(name) return install_dir .. "/parser-info/" .. vim.fn.fnamemodify(name, ":r") .. ".revision" end
  local function sync(kind)
    local from, to = source .. "/" .. kind, install_dir .. "/" .. kind
    vim.fn.mkdir(to, "p")
    local wanted = {}
    for name in vim.fs.dir(from) do
      local link, target = to .. "/" .. name, from .. "/" .. name
      wanted[name] = true
      if catalog_link(link) and uv.fs_readlink(link) ~= target then uv.fs_unlink(link) end
      if not uv.fs_lstat(link) then uv.fs_symlink(target, link) end
    end
    for name in vim.fs.dir(to) do
      if not wanted[name] and catalog_link(to .. "/" .. name) then
        uv.fs_unlink(to .. "/" .. name)
        if kind == "parser" then uv.fs_unlink(revision_file(name)) end
      end
    end
  end
  sync("parser")
  sync("queries")

  -- Record the plugin's revision for linked parsers; :TSUpdate then leaves them to the catalog.
  local ok, parsers = pcall(dofile, treesitter .. "/lua/nvim-treesitter/parsers.lua")
  if not ok then return end
  vim.fn.mkdir(install_dir .. "/parser-info", "p")
  for name in vim.fs.dir(install_dir .. "/parser") do
    local entry = parsers[vim.fn.fnamemodify(name, ":r")]
    local revision = entry and entry.install_info and entry.install_info.revision
    local file = revision_file(name)
    if revision and catalog_link(install_dir .. "/parser/" .. name)
      and table.concat(vim.fn.filereadable(file) == 1 and vim.fn.readfile(file, "b") or {}, "\n") ~= revision then
      -- nvim-treesitter compares the file byte for byte: no trailing newline.
      vim.fn.writefile({ revision }, file, "b")
    end
  end
end

-- Yanks reach the Mac clipboard with OSC 52. Puts use the last yank, and `p` never waits for
-- a terminal clipboard query; paste from the Mac with Cmd+V or :r !pbpaste.
local function use_mac_clipboard()
  if vim.fn.executable("pbcopy") ~= 1 then return end
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = { {}, "v" }
  local function copy(register)
    local direct = osc52.copy(register)
    return function(lines, regtype)
      last = { lines, regtype }
      -- Outside tmux, Neovim writes OSC 52 itself, because commands it starts have no terminal.
      -- Inside tmux, the platform's pbcopy reaches the attached client whatever set-clipboard says.
      if vim.env.TMUX then
        -- Linewise yanks already end with an empty line.
        vim.fn.system({ "pbcopy" }, table.concat(lines, "\n"))
      else
        direct(lines, regtype)
      end
    end
  end
  local function paste() return last end
  vim.g.clipboard = {
    name = "LimaNix",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

return function(paths, flavor)
  use_mac_clipboard()
  vim.opt.rtp:prepend(paths.lazy)
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")
  local parser_dir = vim.fn.stdpath("data") .. "/site"
  link_parsers(paths.parsers, parser_dir, paths.plugins["nvim-treesitter/nvim-treesitter"] or "")

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
      opts = { flavour = flavor },
    },
    { "AstroNvim/astroui", opts = { colorscheme = "catppuccin-" .. flavor } },
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
    { "nvim-treesitter/nvim-treesitter", opts = { install_dir = parser_dir } },
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
