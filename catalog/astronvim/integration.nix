{
  config,
  pkgs,
  configurations,
}:
let
  inherit (import ./smoke-helpers.nix { inherit config pkgs; }) checkLua runEditor;
  languages = configurations.providerConsumer;
  thirdParty = configurations.thirdPartyConsumer;
  userOverride = configurations.userOverrideConsumer;
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
        }) configuration.config.lmx.capabilities.languageSupport.tools
      )
    );
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
