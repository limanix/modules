# Yazi

Configures Yazi, a terminal file manager, with Mocha colors and the preview and
search dependencies included by its Nixpkgs package.

```toml
[nixos]
modules = ["lmx:yazi"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Yazi comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `yazi --version` shows the
installed version.

## Use

Inside the VM, run Yazi from the directory you want to browse:

```console
y
```

It shows directories, file lists, and previews in the terminal. Files you edit
or delete are the files in that directory, including files shared from your Mac.
The `y` function is available in Bash and Zsh. Press `q` to leave Yazi and move
your shell to its current directory; press `Q` to leave without moving the
shell. Run `yazi` directly when you want the file manager without the shell
directory handoff. Selecting Yazi does not enable Zsh.

## Colors and configuration

The default package uses the upstream Yazi binary with a store-backed
[Catppuccin Mocha palette](https://catppuccin.com/palette/) theme. It does not
rebuild Yazi's Rust sources to change colors.

| Configuration | Theme and file behavior |
| -- | -- |
| No personal configuration directory | Uses the default Mocha theme from the Nix store |
| Explicit `YAZI_CONFIG_HOME` | Uses that directory with Yazi's native configuration rules |
| Personal `theme.toml` | Uses your theme with Yazi's native configuration rules |
| Personal settings without `theme.toml` | Keeps your settings through a temporary symlink directory and adds Mocha; your files stay unchanged |
| Managed NixOS settings | Combines Mocha defaults with your ordinary theme overrides |
| A flavor selected in managed settings | Keeps the selected flavor's native precedence without adding Mocha defaults |

Personal configuration is read from an absolute `XDG_CONFIG_HOME` followed by
`/yazi`, or from `~/.config/yazi/` when that variable is unset or relative. For
example, override the directory heading color in a personal `theme.toml`:

```toml
[mgr]
cwd = { fg = "#f5c2e7" }
```

You can also configure Yazi through the standard NixOS `programs.yazi.settings`,
`programs.yazi.flavors`, `programs.yazi.plugins`, and `programs.yazi.initLua`
options in a custom module. These managed options select a Nix-built
configuration directory through `YAZI_CONFIG_HOME`; use them when you want Nix
to own that configuration. That managed directory takes precedence over a
personal `YAZI_CONFIG_HOME` value. An ordinary `programs.yazi.package`
assignment can replace the default package; a bare upstream package bypasses the
default Mocha wrapper. See Yazi's
[configuration reference](https://yazi-rs.github.io/docs/configuration/overview/).

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `programs.yazi.package`, `.settings`, `.flavors`, `.plugins` and `.initLua` |
| Personal configuration | `~/.config/yazi/`, with native `XDG_CONFIG_HOME` and `YAZI_CONFIG_HOME` overrides |
| Integration | Bash and Zsh receive `y`; neither Console nor Zsh is required |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| File manager fails | The shell function returns its failure and cleans the temporary handoff file |
| Shell directory stays unchanged | Use the shell function `y` and quit with `q`; a direct `yazi` process cannot change its parent shell |
| Managed configuration is selected | Its Nix-built directory takes precedence over personal configuration; set overrides through `programs.yazi.settings` |
| Personal keymaps or plugins without a theme | The temporary directory keeps those files and adds Mocha; it is removed on normal exit, failure and handled interruption |
| Theme wrapper receives `SIGKILL` | It cannot clean its `limanix-yazi.*` directory under `TMPDIR`; personal files remain unchanged |
| Yazi package is replaced | A bare package override uses that package's native theme; the vendored default theme matches Yazi 26.5.6 |
| Shared file operations | Moving or deleting mounted files changes the original Mac directory |

## Guarantees

| Guarantee | Covered by |
| -- | -- |
| Enables the configured Yazi package with its packaged preview/search dependencies | `check.nix` |
| Mocha defaults respect explicit directories, personal themes, managed overrides and managed flavors | `tests.nix`: managedOverride, managedFlavor; `smoke.nix`: startup |
| Personal files stay unchanged and temporary overlays are cleaned after exit, failure or handled interruption | `smoke.nix`: startup, errors |
| Bash and Zsh receive the `y` directory-handoff function without enabling Zsh | `tests.nix`: independentShell; `smoke.nix`: startup |
| The default package supports an ordinary NixOS package override | `tests.nix`: packageOverride |
