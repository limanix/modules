# AstroNvim

Provides AstroNvim with a file explorer, fuzzy search, completion, Git UI, diagnostics,
and navigation between Neovim splits and tmux panes.

```toml
[nixos]
modules = ["lmx:astronvim"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
Inside the VM, open a project or file with `nvim`.
The module includes Neovim, Git, and Lazygit; selecting their modules separately is optional.
It also makes Neovim the default `EDITOR` unless a custom module overrides that setting.

## Versions

| Selector | AstroNvim line | Pinned release |
|---|---|---|
| `lmx:astronvim`, `lmx:astronvim-6` | 6 (default) | 6.0.0 |

Upstream maintenance status for this line has not been confirmed.
The catalog records its EOL status as unknown.

The unversioned selector follows the catalog default.
Use `lmx:astronvim-6` to stay on the 6.x line when the catalog default changes.
Minor and patch releases within that line may change in later catalog releases.
Only one AstroNvim line can configure the editor; selecting two different lines is an error.
An explicit line overrides the recommendation included by Console:

```toml
[nixos]
modules = ["lmx:console", "lmx:astronvim-6", "lmx:go"]
```

Selecting the same line through several components configures the editor once.
The selector fixes the AstroNvim major line; Neovim and plugin packages still follow the catalog's base Nixpkgs revision.
It does not freeze their APIs or guarantee compatibility of every personal plugin configuration across catalog updates.

## Packages and state

AstroNvim is pinned to 6.0.0.
The bundled plugin list is read from that release's snapshot rather than maintained separately in the catalog.
Plugin versions and compiled Tree-sitter parsers come from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins), not the snapshot's version constraints.
The editor uses these read-only sources directly; it does not clone plugins on first
launch or update them when you log in. Apply a catalog update to update bundled plugins.
Lazy's cache, lock file, sessions, and Mason installations remain in your user directories.

The base parser list is read from the pinned AstroNvim configuration.
Selected language modules contribute their additional parsers through the NixOS configuration.
Go adds Go and its module formats; Rust adds Rust; Node.js adds JavaScript, TypeScript, and TSX; Python declares Python support.
Nix collects the parsers and their query dependencies into one directory supplied to Tree-sitter through its standard `install_dir` option.
Automatic parser installation is disabled.
The parser and query revisions are selected together by Nixpkgs; `:TSUpdate` is not the update mechanism for this bundled set.

## Language servers

Language modules declare their language servers together with the packages they install.
AstroNvim reads the merged declarations from NixOS and enables those servers through AstroLSP.
The [Go](../go/README.md) module declares `gopls`; [Rust](../rust/README.md) declares `rust-analyzer`.
The editor adapter maps `rust-analyzer` to Neovim's `rust_analyzer` configuration and uses the final declaration's command and arguments.
Python and Node.js declare parsers but do not install or enable language servers.
Installing an additional executable on `PATH` alone does not enable an LSP server.
Enable additional servers, including those supplied by a project environment, through the AstroLSP `servers` option in user configuration.

Mason remains available for explicit additional installations with `:Mason` or
`:LspInstall`; enable additional installed servers through AstroLSP's `servers` option.
Automatic installation and registry refresh at startup are disabled. Nix-provided tools
precede Mason tools on `PATH`. The module enables `nix-ld` by default to support
foreign Linux binaries. This does not guarantee every Mason package works on NixOS:
individual tools may also need libraries, an interpreter, or a compiler. Mason installs
need network access and are user-managed, outside the catalog's package pins.
To disable this compatibility loader, set `programs.nix-ld.enable = false` in a custom module.

## Personal configuration

An existing `~/.config/nvim/init.lua` or `init.vim` takes precedence over the bundled
AstroNvim setup. The module never replaces these files.

To customize the bundled setup, add Lazy plugin specifications under
`~/.config/nvim/lua/plugins/`. For example, `lua/plugins/editor.lua`:

```lua
return {
  "AstroNvim/astrolsp",
  opts = { formatting = { format_on_save = false } },
}
```

An optional `~/.config/nvim/lua/polish.lua` runs after setup.
Bundled plugins stay in the Nix store. Additional user plugins can be installed
explicitly with `:Lazy install`; startup does not download missing plugins.
XDG configuration, data, state, and cache directory overrides are respected.

## Terminal integration

Space is the leader key. Press it and pause for the shortcut hints.
`Space e` opens the file explorer, `Space f f` finds files, and `Space g g` opens Lazygit.
With the [tmux module](../tmux/README.md), `Ctrl-h/j/k/l` moves between editor splits
and terminal panes; `Alt-h/j/k/l` resizes them. Smart-splits loads at startup to mark
the active Neovim pane for tmux.

Configure a Nerd Font and true color support in the terminal on macOS.
For an SSH session the font belongs on the host, not in the VM.
Clipboard support depends on the terminal and multiplexer; the module does not
provide a graphical clipboard inside the VM.

See the [AstroNvim guide](https://docs.astronvim.com/) and
[LSP configuration](https://docs.astronvim.com/recipes/advanced_lsp/) for editor usage.

## Guarantees

| Guarantee | Covered by |
|---|---|
| The default and explicit `6` selector install the pinned AstroNvim line with Neovim and Lazygit | `check.nix`, `tests.nix`: defaultEntryPoint, dependencies |
| Console recommends the default line; an explicit line wins independently of import order | `checks/integration.nix`: console.astronvimVersionSelection |
| An existing XDG Neovim `init.lua` or `init.vim` takes precedence; otherwise the bundled setup starts | `smoke.nix`: startup, personalLua, personalVim |
| Personal `lua/polish.lua` runs after bundled setup | `smoke.nix`: polish |
| Personal Lazy specifications under the XDG Neovim `lua/plugins/` directory extend bundled setup | `smoke.nix`: personalPlugins |
| Bundled startup disables automatic plugin installation and update checking | `smoke.nix`: startup |
| Lua buffers receive active bundled Tree-sitter highlighting; language declarations add their parsers | `smoke.nix`: startup; `integration.nix`: lsp |
| The declared `gopls` and `rust-analyzer` attach using their final command; providers remain optional | `tests.nix`, `checks/integration.nix`, `integration.nix`: lsp |
| Third-party declarations and user overrides supply the LSP executable and its arguments | `checks/integration.nix`, `integration.nix`: thirdParty, userOverride |
| Leader explorer/search/Git bindings and Ctrl/Alt navigation are configured | `smoke.nix`: startup |
| Users may override `programs.neovim.defaultEditor` and disable `programs.nix-ld.enable` | `tests.nix` |
