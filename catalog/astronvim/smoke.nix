{
  config,
  pkgs,
  ...
}:
let
  inherit (import ./smoke-helpers.nix { inherit config pkgs; }) checkLua runEditor;
  editor = config.programs.neovim.finalPackage;
  startupCheck = pkgs.writeText "astronvim-startup.lua" ''
    assert(package.loaded.lazy, "bundled Lazy startup did not run")
    assert(vim.g.colors_name == "catppuccin-mocha", "default Mocha theme did not load")
    assert(require("lazy.core.config").plugins.AstroNvim, "AstroNvim is absent")
    for name, plugin in pairs(require("lazy.core.config").plugins) do
      assert(vim.fn.fnamemodify(plugin.dir, ":t") == name,
        "plugin source basename breaks require-triggered loading: " .. name)
    end
    local buffer = vim.api.nvim_get_current_buf()
    assert(vim.wait(10000, function()
      return vim.treesitter.highlighter.active[buffer] ~= nil
    end), "Lua buffer has no active Tree-sitter highlighting")
    for _, key in ipairs({ "<Space>e", "<Space>ff", "<Space>gg", "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<M-h>", "<M-j>", "<M-k>", "<M-l>" }) do
      -- Neovim exposes the applied Ctrl-j mapping as the newline key.
      local applied = key == "<C-j>" and "<NL>" or key
      assert(vim.fn.maparg(applied, "n") ~= "", "missing key binding: " .. key)
    end
    assert(require("lazy.core.config").options.install.missing == false)
    assert(require("lazy.core.config").options.checker.enabled == false)
  '';
  personalCheck =
    kind:
    pkgs.writeText "astronvim-personal-${kind}.lua" ''
      assert(vim.g.lmx_personal == "${kind}")
      assert(not package.loaded.lazy)
    '';
  polishCheck = pkgs.writeText "astronvim-polish.lua" ''
    assert(vim.g.lmx_polish, "personal polish.lua did not run")
  '';
  pluginsCheck = pkgs.writeText "astronvim-personal-plugins.lua" ''
    assert(vim.g.lmx_personal_plugin, "personal plugin specification did not run")
    assert(package.loaded.lazy, "personal plugin configuration replaced bundled setup")
    assert(vim.g.colors_name == "astrodark", "personal theme did not override Mocha")
  '';

in
{
  sessions =
    pkgs.runCommand "astronvim-session-lifecycle"
      {
        nativeBuildInputs = [
          editor
          pkgs.python3
          pkgs.coreutils
          config.programs.git.package
          config.programs.lazygit.package
        ];
      }
      ''
        python ${./session-smoke.py} --editor ${editor}/bin/nvim \
          --fixture-parent "$TMPDIR" --report "$TMPDIR/session-report.json"
        touch "$out"
      '';
  startup = runEditor "astronvim-startup" editor ''
    printf 'local value = 1\n' > example.lua
    run_nvim example.lua -c ${pkgs.lib.escapeShellArg (checkLua startupCheck)}
  '';
  personalLua = runEditor "astronvim-personal-lua" editor ''
    printf 'vim.g.lmx_personal = "lua"\n' > "$XDG_CONFIG_HOME/nvim/init.lua"
    printf 'let g:lmx_personal = "vim"\n' > "$XDG_CONFIG_HOME/nvim/init.vim"
    run_nvim -c ${pkgs.lib.escapeShellArg (checkLua (personalCheck "lua"))}
  '';
  personalVim = runEditor "astronvim-personal-vim" editor ''
    printf 'let g:lmx_personal = "vim"\n' > "$XDG_CONFIG_HOME/nvim/init.vim"
    run_nvim -c ${pkgs.lib.escapeShellArg (checkLua (personalCheck "vim"))}
  '';
  polish = runEditor "astronvim-polish" editor ''
    mkdir -p "$XDG_CONFIG_HOME/nvim/lua"
    printf 'vim.g.lmx_polish = true\n' > "$XDG_CONFIG_HOME/nvim/lua/polish.lua"
    run_nvim -c ${pkgs.lib.escapeShellArg (checkLua polishCheck)}
  '';
  personalPlugins = runEditor "astronvim-personal-plugins" editor ''
    mkdir -p "$XDG_CONFIG_HOME/nvim/lua/plugins"
    cat > "$XDG_CONFIG_HOME/nvim/lua/plugins/check.lua" <<'LUA'
    return {
      { "AstroNvim/astroui", opts = { colorscheme = "astrodark" } },
      {
        "AstroNvim/astrocore",
        opts = function() vim.g.lmx_personal_plugin = true end,
      },
    }
    LUA
    run_nvim -c ${pkgs.lib.escapeShellArg (checkLua pluginsCheck)}
  '';
}
