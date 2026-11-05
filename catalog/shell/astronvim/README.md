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

The base parser list is read from the pinned AstroNvim configuration, and the
module adds parsers for Dockerfile, JSON, TOML and YAML files. Each selected
[toolchain](https://docs.limanix.dev/modules/#toolchains) adds the parsers of
its languages through the NixOS configuration. Nix builds these parsers with
their queries, and at each start the editor links them into Tree-sitter's
install directory, `~/.local/share/nvim/site`. Automatic parser installation is
disabled. A catalog update replaces the links; `:TSUpdate` leaves catalog
parsers alone.

For another language, run `:TSInstall LANGUAGE`. It downloads and compiles the
parser into the same directory; the module provides `curl`, the `tree-sitter`
CLI and a C compiler. Open files of that language switch to the new parser when
the installation finishes. Parsers installed this way are yours: `:TSUpdate`
updates them, and after a catalog update that brings a newer nvim-treesitter,
run `:TSUpdate` to keep them compatible with it. `:TSInstall! LANGUAGE` replaces
a catalog parser with your own build; `:TSUninstall LANGUAGE` returns to the
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

### Tools from Mason

Mason installs language servers, linters, formatters and debuggers that no
toolchain provides. It keeps them in `~/.local/share/nvim/mason` in the VM: the
catalog does not pin them, and a new VM starts without them. `:Mason` lists the
packages. Installation needs network access and the package manager of the
tool's language, such as `npm` from the `nodejs` toolchain or `pip` from
`python`. The catalog has no toolchain for Ruby, PHP or Julia and no LuaRocks,
so packages that need them fail; for example, `rubocop` stops with
`Could not find executable "gem" in PATH`.

| Package | Install | Then |
| -- | -- | -- |
| Language server | `:MasonInstall dockerfile-language-server` | Add `dockerls` to AstroLSP's `servers` |
| Linter or formatter | `:MasonInstall hadolint` | Nothing: none-ls runs it |
| Debugger | `:MasonInstall debugpy` | Nothing: mason-nvim-dap sets it up for `F5` |
| Tree-sitter parser | `:TSInstall helm` | Nothing |

Automatic installation and registry refresh at startup are disabled. Mason's
`bin` folder comes last on `PATH`, so a tool from Nix takes precedence over a
Mason tool with the same name. Mason tools are generic Linux binaries, which run
with [nix-ld](https://github.com/nix-community/nix-ld), on in every LimaNix VM;
a tool can still need libraries, an interpreter or a compiler.

AstroLSP starts only the servers in its `servers` list. Some servers also need a
file type that Neovim does not detect: `helm_ls` starts in `helm` files, and
Neovim opens Helm templates as `yaml`. A personal specification, such as
`~/.config/nvim/lua/plugins/lsp.lua`, does both:

```lua
return {
  {
    "AstroNvim/astrolsp",
    opts = { servers = { "dockerls", "helm_ls" } },
  },
  {
    "AstroNvim/astrocore",
    opts = {
      filetypes = {
        pattern = {
          [".*/templates/.*%.yaml"] = "helm",
          [".*/templates/.*%.tpl"] = "helm",
        },
      },
    },
  },
}
```

To get the same tools in every VM, keep these specifications in
`.config/nvim/lua/plugins` of your
[dotfiles](https://docs.limanix.dev/config/dotfiles), without an `init.lua`: it
would replace the bundled setup. List the Mason packages for
mason-tool-installer:

```lua
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  opts = {
    ensure_installed = { "dockerfile-language-server", "hadolint", "debugpy", "helm-ls" },
  },
}
```

In a new VM, run `:MasonToolsInstall` once. A tool that every VM needs can come
from the catalog instead: select the toolchain that provides it, or declare it
in a custom module through the
[language support capability](../../_shared/README.md#share-language-tools).

## Debuggers

A toolchain with a debugger declares it next to its language server; the
toolchain's page names it. AstroNvim gives nvim-dap the adapter and launch
configurations that mason-nvim-dap defines for that debugger, started with the
declared command. In a file of that language, `F5` asks which configuration to
run, such as the program or the tests of the current file, and starts it. `F9`
toggles a breakpoint, and `Space d` shows the other debugger keys.

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

Each theme in `[theme]` of `limanix.toml` draws the editor with its own Neovim
colorscheme from the catalog's Nixpkgs. The colorscheme's background setting
turns its background off, and the terminal's background shows through:

| Theme | Plugin | Colorscheme | Background setting |
| -- | -- | -- | -- |
| `catppuccin-mocha` | catppuccin-nvim | `catppuccin-mocha` | `transparent_background = true` |
| `tokyo-night` | tokyonight.nvim | `tokyonight-night` | `transparent = true`; `styles.sidebars` and `styles.floats` are `"transparent"` |
| `dracula` | dracula.nvim | `dracula` | `transparent_bg = true` |
| `nord` | nord.nvim | `nord` | `vim.g.nord_disable_background = true` |
| `gruvbox-dark` | gruvbox.nvim | `gruvbox` | `transparent_mode = true` |
| `rose-pine` | rose-pine | `rose-pine-main` | `styles.transparency = true` |
| `kanagawa-wave` | kanagawa.nvim | `kanagawa-wave` | `transparent = true` |
| `everforest-dark` | everforest | `everforest` | `vim.g.everforest_transparent_background = 1` |
| `solarized-light` | nvim-solarized-lua | `solarized` | `vim.g.solarized_termtrans = 1` |
| `github-light` | github-nvim-theme | `github_light_default` | `options.transparent = true` |

Settings without `vim.g` go to the plugin's `setup`. In every theme the text
area and the file tree show the terminal's background; floating windows, bars
and, in some colorschemes, the line-number column keep their own colors. With
the default `system` theme the colorscheme is Catppuccin with a transparent
background. The light or dark background that Neovim detects in the terminal
chooses Latte or Mocha for the text. A theme without a colorscheme of its own
draws its palette with Catppuccin's, also on the terminal's background. For the
theme's own background, choose the same theme in your terminal on the Mac. For
another colorscheme, assign AstroUI's `colorscheme` in a personal Lazy
specification:

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
| Services | No daemon; plugins, parsers, language servers and debuggers run with the editor |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Existing init file | Your `init.lua` or `init.vim` replaces the bundled startup; remove it only when you choose to use the catalog setup |
| Missing language server | Select a provider or declare the tool through the public capability; a binary on PATH alone is insufficient |
| Foreign plugin or Mason tool | Extra tools may need libraries or interpreters; add libraries to `programs.nix-ld.libraries` in a custom module |
| Two AstroNvim lines | Choose one line; different supported lines fail with `astronvim: select one line` |
| Terminal background far from the theme's | The editor draws the theme's text colors on the terminal's background; choose the same theme in your terminal |
| `:TSInstall` for a new language | Downloads the grammar and compiles it in the guest; needs network access |
| Catalog update with a newer nvim-treesitter | Catalog parsers update with it; run `:TSUpdate` for parsers you installed |
| Unsaved edits or running terminal jobs | Save edits and finish jobs; restoring a session restores layout and file positions rather than unsaved contents or processes |
| Resume a saved session | Save current edits first; the example above replaces the current editor layout |
