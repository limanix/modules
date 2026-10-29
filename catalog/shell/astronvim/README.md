# AstroNvim

Provides AstroNvim with a file explorer, fuzzy search, completion, Git UI,
diagnostics, and navigation between Neovim splits and tmux panes.

## Select

The `terminal` shell preset uses AstroNvim as its editor by default:

```toml
[shell]
editor = "astronvim" # or "neovim" or "none"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. Inside the VM, open a project or file with `nvim`. The
module includes Neovim, Git, and Lazygit. It also makes Neovim the default
`EDITOR` unless a custom module overrides that setting.

## Versions

| AstroNvim line | Pinned release |
| -- | -- |
| 6 (default) | 6.0.0 |

Upstream maintenance status for this line has not been confirmed. The catalog
records its EOL status as unknown.

The client installs the catalog's default line. Minor and patch releases within
that line may change in later catalog releases, and a later catalog may make a
new major line the default. Only one AstroNvim line can configure the editor:
two different lines fail with `astronvim: select one line`. Neovim and plugin
packages follow the catalog's base Nixpkgs revision. The line does not freeze
their APIs or guarantee compatibility of every personal plugin configuration
across catalog updates.

## Use

Inside the VM, open your project directory:

```console
nvim .
```

Space is the leader key: press it and pause for hints. See
[Terminal integration](#terminal-integration) for common keys and
[Language servers](#language-servers) for editor support.

## Packages and state

AstroNvim is pinned to 6.0.0. The bundled plugin list is read from that
release's snapshot rather than maintained separately in the catalog. Plugin
versions and compiled Tree-sitter parsers come from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions),
not the snapshot's version constraints. The editor uses these read-only sources
directly; it does not clone plugins on first launch or update them when you log
in. Apply a catalog update to update bundled plugins. Lazy's cache, lock file,
sessions, and Mason installations remain in your user directories.

The base parser list is read from the pinned AstroNvim configuration. Each
selected [toolchain](https://docs.limanix.dev/modules/#toolchains) adds the
parsers of its languages through the NixOS configuration. Nix builds these
parsers with their queries, and at each start the editor links them into
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

Each selected toolchain declares its language server together with the packages
it installs; the toolchain's page names the server. AstroNvim reads the merged
declarations from NixOS and enables those servers through AstroLSP. The editor
adapter maps `rust-analyzer` to `rust_analyzer` and `typescript-language-server`
to `ts_ls`. Each server uses its final declaration's command and arguments.
Installing an additional executable on `PATH` alone does not enable an LSP
server. Enable additional servers, including those supplied by a project
environment, through the AstroLSP `servers` option in user configuration.

Mason remains available for explicit additional installations with `:Mason` or
`:LspInstall`; enable additional installed servers through AstroLSP's `servers`
option. Automatic installation and registry refresh at startup are disabled.
Nix-provided tools precede Mason tools on `PATH`. Mason tools are generic Linux
binaries, which run with [nix-ld](https://github.com/nix-community/nix-ld), on
in every LimaNix VM. This does not guarantee every Mason package works on NixOS:
individual tools may also need libraries, an interpreter, or a compiler. Mason
installs need network access and are user-managed, outside the catalog's package
pins.

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

The bundled colorscheme is Catppuccin. With the default `system` flavor its
background is transparent. The terminal's background shows through. The light or
dark background that Neovim detects in the terminal chooses Latte or Mocha for
the text. A Catppuccin flavor in `[theme]` of `limanix.toml` uses that flavor
with its own background. For another theme, assign AstroUI's `colorscheme` in a
personal Lazy specification:

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

Yanks go to the Mac clipboard: inside tmux through the platform's `pbcopy`,
outside tmux as an OSC 52 sequence that Neovim writes itself. `p` puts the last
yank without asking the terminal and never waits for a clipboard read. Paste
from the Mac with Cmd+V in insert mode, or insert it with `:r !pbpaste`. The
terminal on the Mac must allow OSC 52; see
[Terminal and clipboard](https://docs.limanix.dev/inside/clipboard).

See the [AstroNvim guide](https://docs.astronvim.com/) and
[LSP configuration](https://docs.astronvim.com/recipes/advanced_lsp/) for editor
usage.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Standard settings | `programs.neovim.defaultEditor` remains overridable |
| Personal configuration | Native Neovim XDG directory: `init.lua`, `init.vim`, `lua/plugins/` and `lua/polish.lua` |
| Integration | Consumes public language-support declarations; imports Neovim, Git and Lazygit |
| Services | No daemon; plugins, parsers and language servers run with the editor |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Existing init file | Your `init.lua` or `init.vim` replaces the bundled startup; remove it only when you choose to use the catalog setup |
| Missing language server | Select a provider or declare the tool through the public capability; a binary on PATH alone is insufficient |
| Foreign plugin or Mason tool | Extra tools may need libraries or interpreters; add libraries to `programs.nix-ld.libraries` in a custom module |
| Two AstroNvim lines | Choose one line; different supported lines fail with `astronvim: select one line` |
| `:TSInstall` for a new language | Downloads the grammar and compiles it in the guest; needs network access |
| Catalog update with a newer nvim-treesitter | Catalog parsers update with it; run `:TSUpdate` for parsers you installed |
| Unsaved edits or running terminal jobs | Save edits and finish jobs; restoring a session restores layout and file positions rather than unsaved contents or processes |
| Resume a saved session | Save current edits first; the example above replaces the current editor layout |
