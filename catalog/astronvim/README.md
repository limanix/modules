# AstroNvim

Provides AstroNvim with a file explorer, fuzzy search, completion, Git UI,
diagnostics, and navigation between Neovim splits and tmux panes.

```toml
[nixos]
modules = ["lmx:astronvim"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
Inside the VM, open a project or file with `nvim`. The module includes Neovim,
Git, and Lazygit; selecting their modules separately is optional. It also makes
Neovim the default `EDITOR` unless a custom module overrides that setting.

## Versions

| Selector | AstroNvim line | Pinned release |
| -- | -- | -- |
| `lmx:astronvim`, `lmx:astronvim-6` | 6 (default) | 6.0.0 |

Upstream maintenance status for this line has not been confirmed. The catalog
records its EOL status as unknown.

The unversioned selector follows the catalog default. Use `lmx:astronvim-6` to
stay on the 6.x line when the catalog default changes. Minor and patch releases
within that line may change in later catalog releases. Only one AstroNvim line
can configure the editor. Selecting two different supported lines fails with
`astronvim: select one line`. An explicit line overrides the recommendation
included by Console:

```toml
[nixos]
modules = ["lmx:console", "lmx:astronvim-6", "lmx:go"]
```

Selecting the same line through several components configures the editor once.
The selector fixes the AstroNvim major line; Neovim and plugin packages still
follow the catalog's base Nixpkgs revision. It does not freeze their APIs or
guarantee compatibility of every personal plugin configuration across catalog
updates.

## Packages and state

AstroNvim is pinned to 6.0.0. The bundled plugin list is read from that
release's snapshot rather than maintained separately in the catalog. Plugin
versions and compiled Tree-sitter parsers come from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins),
not the snapshot's version constraints. The editor uses these read-only sources
directly; it does not clone plugins on first launch or update them when you log
in. Apply a catalog update to update bundled plugins. Lazy's cache, lock file,
sessions, and Mason installations remain in your user directories.

The base parser list is read from the pinned AstroNvim configuration. Selected
language modules contribute their additional parsers through the NixOS
configuration. Go adds Go and its module formats; Rust adds Rust; Node.js adds
JavaScript, TypeScript, and TSX; Python declares Python support. Nix builds
these parsers with their queries, and at each start the editor links them into
Tree-sitter's install directory, `~/.local/share/nvim/site`. Automatic parser
installation is disabled. A catalog update replaces the links; `:TSUpdate`
leaves catalog parsers alone.

For another language, run `:TSInstall LANGUAGE`. It downloads and compiles the
parser into the same directory; the module provides `curl`, the `tree-sitter`
CLI and a C compiler. Parsers installed this way are yours: `:TSUpdate` updates
them, and after a catalog update that brings a newer nvim-treesitter, run
`:TSUpdate` to keep them compatible with it. `:TSInstall! LANGUAGE` replaces a
catalog parser with your own build; `:TSUninstall LANGUAGE` returns to the
catalog parser at the next start. To have Nix build and pin an additional parser
instead, declare it in a custom module, for example
`lmx.capabilities.languageSupport.languages.zig.parsers = [ "zig" ];`.

## Language servers

Language modules declare their language servers together with the packages they
install. AstroNvim reads the merged declarations from NixOS and enables those
servers through AstroLSP. The [Go](../go/README.md) module declares `gopls`;
[Rust](../rust/README.md) declares `rust-analyzer`. The
[Python](../python/README.md) module declares Pyright;
[Node.js](../nodejs/README.md) declares the JavaScript/TypeScript language
server. The editor adapter maps `rust-analyzer` to `rust_analyzer` and
`typescript-language-server` to `ts_ls`. Each server uses its final
declaration's command and arguments. Installing an additional executable on
`PATH` alone does not enable an LSP server. Enable additional servers, including
those supplied by a project environment, through the AstroLSP `servers` option
in user configuration.

Mason remains available for explicit additional installations with `:Mason` or
`:LspInstall`; enable additional installed servers through AstroLSP's `servers`
option. Automatic installation and registry refresh at startup are disabled.
Nix-provided tools precede Mason tools on `PATH`. The module enables `nix-ld` by
default to support foreign Linux binaries. This does not guarantee every Mason
package works on NixOS: individual tools may also need libraries, an
interpreter, or a compiler. Mason installs need network access and are
user-managed, outside the catalog's package pins. To disable this compatibility
loader, set `programs.nix-ld.enable = false` in a custom module.

## Personal configuration

An existing `~/.config/nvim/init.lua` or `init.vim` takes precedence over the
bundled AstroNvim setup. The module never replaces these files.

To customize the bundled setup, add Lazy plugin specifications under
`~/.config/nvim/lua/plugins/`. For example, `lua/plugins/editor.lua`:

```lua
return {
  "AstroNvim/astrolsp",
  opts = { formatting = { format_on_save = false } },
}
```

An optional `~/.config/nvim/lua/polish.lua` runs after setup. Bundled plugins
stay in the Nix store. Additional user plugins can be installed explicitly with
`:Lazy install`; startup does not download missing plugins. XDG configuration,
data, state, and cache directory overrides are respected.

The bundled colorscheme is Catppuccin in the guest's flavor: Mocha, unless
`[theme]` in `limanix.toml` selects another. For another theme, assign AstroUI's
`colorscheme` in a personal Lazy specification:

```lua
return {
  "AstroNvim/astroui",
  opts = { colorscheme = "astrodark" },
}
```

## Save and resume a project

AstroNvim's bundled Resession plugin provides session saving and loading. Normal
editor exit with project file buffers automatically saves the last session and a
snapshot for the project directory. After starting a new `nvim` process, resume
the last session with:

```vim
:lua require("resession").load("Last Session", { reset = true })
```

Resuming restores the project directory, named file buffers, splits and cursor
positions. Later normal exits update the saved session with your new layout and
positions. Save file changes before exiting or replacing a session; session
snapshots do not preserve unsaved file contents or running processes. These
defaults apply to the bundled setup; a personal init file can replace its
session behavior.

## Terminal integration

Space is the leader key. Press it and pause for the shortcut hints. `Space e`
opens the file explorer, `Space f f` finds files, and `Space g g` opens Lazygit.
With the [tmux module](../tmux/README.md), `Ctrl-h/j/k/l` moves between editor
splits and terminal panes; `Alt-h/j/k/l` resizes them. Smart-splits loads at
startup to mark the active Neovim pane for tmux.

Configure a Nerd Font and true color support in the terminal on macOS. For an
SSH session the font belongs on the host, not in the VM.

Yanks go to the Mac clipboard through the platform's `pbcopy`, inside or outside
tmux. `p` puts the last yank without asking the terminal, so it never waits for
a clipboard read. Paste from the Mac with Cmd+V in insert mode, or insert it
with `:r !pbpaste`. The terminal on the Mac must allow OSC 52; see
[Terminal and clipboard](https://limanix.dev/terminal.html).

See the [AstroNvim guide](https://docs.astronvim.com/) and
[LSP configuration](https://docs.astronvim.com/recipes/advanced_lsp/) for editor
usage.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Standard settings | `programs.neovim.defaultEditor` and `programs.nix-ld.enable` remain overridable |
| Personal configuration | Native Neovim XDG directory: `init.lua`, `init.vim`, `lua/plugins/` and `lua/polish.lua` |
| Integration | Consumes public language-support declarations; imports Neovim, Git and Lazygit |
| Services | No daemon; plugins, parsers and language servers run with the editor |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Existing init file | Your `init.lua` or `init.vim` replaces the bundled startup; remove it only when you choose to use the catalog setup |
| Missing language server | Select a provider or declare the tool through the public capability; a binary on PATH alone is insufficient |
| Foreign plugin or Mason tool | Extra tools may need libraries or interpreters even with nix-ld enabled |
| Two AstroNvim lines | Choose one line; different supported lines fail with `astronvim: select one line` |
| `:TSInstall` for a new language | Downloads the grammar and compiles it in the guest; needs network access |
| Catalog update with a newer nvim-treesitter | Catalog parsers update with it; run `:TSUpdate` for parsers you installed |
| Unsaved edits or running terminal jobs | Save edits and finish jobs; restoring a session restores layout and file positions rather than unsaved contents or processes |
| Resume a saved session | Save current edits first; the example above replaces the current editor layout |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| The configured editor, Git and Lazygit are installed | `eval.line-6` |
| Editor and compatibility-loader preferences accept ordinary settings | `eval.preferences` |
| Language providers remain optional; catalog and third-party declarations are accepted | `eval.optionalProviders`, `eval.catalogProvider`, `eval.thirdPartyProvider` |
| Rust and TypeScript server names are translated; other identities are preserved | `eval.serverNames` |
| Bundled startup loads Mocha, key bindings and Lua highlighting from immutable plugin sources | `run.commands-6` |
| The bundled setup receives the guest's flavor | `eval.theme` |
| Personal init files replace bundled startup and remain unchanged | `run.personalLua`, `run.personalVim` |
| Personal polish and plugin specifications extend the bundled setup | `run.polish`, `run.personalPlugins` |
| Yanks reach `pbcopy`, and puts use the last yank without a clipboard read | `run.clipboard` |
| A catalog Rust server and a guarded third-party Go server attach with the declared command, arguments and highlighting | `run.languageServer` |

Removing this module removes its declarations and bundled store packages when no
other selected module imports it. It does not delete personal Neovim files,
Mason tools, session snapshots or other XDG state. Links to catalog parsers stay
in `~/.local/share/nvim/site` and break once Nix removes the old packages;
before using Neovim without this module, delete them with
`find ~/.local/share/nvim/site -lname '*-astronvim-parsers/*' -delete`.
