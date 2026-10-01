{
  config,
  pkgs,
  evaluate,
  ...
}:
let
  checkLua =
    script:
    "luafile ${pkgs.writeText "astronvim-run-check.lua" ''
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.schedule(function()
            local ok, failure = pcall(function()
              assert(vim.v.vim_did_enter == 1, "smoke ran before VimEnter")
              dofile([[${script}]])
              assert(vim.v.errmsg == "", vim.v.errmsg)
            end)
            if not ok then
              vim.api.nvim_err_writeln(tostring(failure))
              vim.cmd("cquit 1")
            else
              vim.cmd("qa!")
            end
          end)
        end,
      })
    ''}";
  runEditor =
    name: editor: script:
    pkgs.runCommand name
      {
        nativeBuildInputs = [
          editor
          pkgs.coreutils
          pkgs.gnugrep
          config.programs.git.package
          pkgs.lazygit
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_DATA_HOME="$TMPDIR/data"
        export XDG_STATE_HOME="$TMPDIR/state"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_STATE_HOME"
        run_nvim() {
          if ! timeout 90 nvim --headless "$@" > "$TMPDIR/nvim.log" 2>&1; then
            cat "$TMPDIR/nvim.log"
            return 1
          fi
          cat "$TMPDIR/nvim.log"
          # Errors from exit autocmds do not reliably set Neovim's process status.
          if grep -E 'Error in|Error detected|Error executing|E[0-9]+:' "$TMPDIR/nvim.log"; then
            return 1
          fi
        }
        ${script}
        touch "$out"
      '';
  editor = config.programs.neovim.finalPackage;
  startupCheck = pkgs.writeText "astronvim-startup.lua" ''
    assert(package.loaded.lazy, "bundled Lazy startup did not run")
    assert(require("lazy.core.config").plugins.AstroNvim, "AstroNvim is absent")
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
  '';
  languages = evaluate [
    ../go/default.nix
    ../rust/default.nix
  ];
  lspCheck =
    name:
    pkgs.writeText "astronvim-${name}.lua" ''
      assert(vim.wait(20000, function()
        return #vim.lsp.get_clients({ bufnr = 0, name = "${name}" }) == 1
      end), "declared ${name} did not attach")
      local client = vim.lsp.get_clients({ bufnr = 0, name = "${name}" })[1]
      local declarations = vim.json.decode(table.concat(vim.fn.readfile(vim.env.LMX_TOOLS), "\n"))
      local tool = declarations["${if name == "rust_analyzer" then "rust-analyzer" else name}"]
      assert(vim.deep_equal(client.config.cmd, vim.list_extend({ tool.command }, tool.args)),
        "LSP command or arguments differ from selected provider")
      local buffer = vim.api.nvim_get_current_buf()
      assert(vim.wait(10000, function()
        return vim.treesitter.highlighter.active[buffer] ~= nil
      end), "language buffer has no active Tree-sitter highlighting")
    '';
  toolDeclarations =
    configuration:
    pkgs.writeText "editor-tools.json" (
      builtins.toJSON (
        builtins.mapAttrs (_: tool: {
          inherit (tool) command args;
        }) configuration.config.lmx.capabilities.editor.tools
      )
    );
  suppliedGopls = pkgs.writeShellScriptBin "gopls" ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${pkgs.gopls}/bin/gopls "$@"
  '';
  suppliedTool = {
    package = suppliedGopls;
    command = "${suppliedGopls}/bin/gopls";
    args = [ "--catalog-smoke" ];
    languages = [ "go" ];
  };
  thirdParty = evaluate [
    {
      environment.systemPackages = [
        pkgs.go
        suppliedGopls
      ];
      lmx.capabilities.editor = {
        tools.gopls = suppliedTool;
        languages.go.parsers = [ "go" ];
      };
    }
  ];
  userOverride = evaluate [
    ../go/default.nix
    { lmx.capabilities.editor.tools.gopls = suppliedTool; }
  ];
  checkGo =
    name: configuration:
    runEditor name configuration.config.programs.neovim.finalPackage ''
      export PATH="${pkgs.lib.makeBinPath configuration.config.environment.systemPackages}:$PATH"
      export LMX_TOOLS=${toolDeclarations configuration}
      mkdir project
      cd project
      printf 'module example\n\ngo 1.24\n' > go.mod
      printf 'package main\nfunc main() {}\n' > main.go
      run_nvim main.go -c ${pkgs.lib.escapeShellArg (checkLua (lspCheck "gopls"))}
    '';
in
{
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
      {
        "AstroNvim/astrocore",
        opts = function() vim.g.lmx_personal_plugin = true end,
      },
    }
    LUA
    run_nvim -c ${pkgs.lib.escapeShellArg (checkLua pluginsCheck)}
  '';
  lsp = runEditor "astronvim-declared-servers" languages.config.programs.neovim.finalPackage ''
    export PATH="${pkgs.lib.makeBinPath languages.config.environment.systemPackages}:$PATH"
    export LMX_TOOLS=${toolDeclarations languages}
    mkdir project
    cd project
    printf 'module example\n\ngo 1.24\n' > go.mod
    printf 'package main\nfunc main() {}\n' > main.go
    run_nvim main.go -c ${pkgs.lib.escapeShellArg (checkLua (lspCheck "gopls"))}
    printf '[package]\nname="example"\nversion="0.1.0"\nedition="2021"\n' > Cargo.toml
    mkdir src
    printf 'fn main() {}\n' > src/main.rs
    run_nvim src/main.rs -c ${pkgs.lib.escapeShellArg (checkLua (lspCheck "rust_analyzer"))}
  '';
  thirdParty = checkGo "astronvim-third-party-server" thirdParty;
  userOverride = checkGo "astronvim-user-overridden-server" userOverride;
}
