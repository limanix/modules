{
  config,
  pkgs,
  configurations,
}:
let
  inherit (import ./smoke-helpers.nix { inherit config pkgs; }) checkLua runEditor;
  serverName = import ../server-name.nix;
  inherit (configurations) catalog thirdParty;
  lspCheck =
    identity:
    pkgs.writeText "astronvim-${identity}.lua" ''
      assert(vim.wait(20000, function()
        return #vim.lsp.get_clients({ bufnr = 0, name = "${serverName identity}" }) == 1
      end), "declared ${identity} did not attach")
      local client = vim.lsp.get_clients({ bufnr = 0, name = "${serverName identity}" })[1]
      local declarations = vim.json.decode(table.concat(vim.fn.readfile(vim.env.LMX_TOOLS), "\n"))
      local tool = declarations["${identity}"]
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
        }) configuration.config.lmx.capabilities.languageSupport.tools
      )
    );
in
runEditor "astronvim-language-servers" catalog.config.programs.neovim.finalPackage ''
  export PATH="${catalog.config.system.path}/bin:$PATH"
  export LMX_TOOLS=${toolDeclarations catalog}
  test "$(readlink -f "$(command -v nvim)")" = \
    "$(readlink -f ${catalog.config.programs.neovim.finalPackage}/bin/nvim)"
  mkdir catalog-project
  cd catalog-project
  printf '[package]\nname="example"\nversion="0.1.0"\nedition="2021"\n' > Cargo.toml
  mkdir src
  printf 'fn main() {}\n' > src/main.rs
  run_nvim src/main.rs -c ${pkgs.lib.escapeShellArg (checkLua (lspCheck "rust-analyzer"))}

  cd "$TMPDIR"
  export PATH="${thirdParty.config.system.path}/bin:$PATH"
  export LMX_TOOLS=${toolDeclarations thirdParty}
  export XDG_CONFIG_HOME="$TMPDIR/third-party/config"
  export XDG_DATA_HOME="$TMPDIR/third-party/data"
  export XDG_STATE_HOME="$TMPDIR/third-party/state"
  export XDG_CACHE_HOME="$TMPDIR/third-party/cache"
  mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_STATE_HOME" third-party-project
  test "$(readlink -f "$(command -v nvim)")" = \
    "$(readlink -f ${thirdParty.config.programs.neovim.finalPackage}/bin/nvim)"
  cd third-party-project
  printf 'module example\n\ngo 1.24\n' > go.mod
  printf 'package main\nfunc main() {}\n' > main.go
  run_nvim main.go -c ${pkgs.lib.escapeShellArg (checkLua (lspCheck "gopls"))}
''
