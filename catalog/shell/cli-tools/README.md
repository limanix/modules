# CLI tools

Installs tools for finding files, reading code and data, making HTTP requests,
and inspecting the VM. Also enables Git and configures delta as its diff pager.

## Select

Both shell presets include these tools; there is no selector for them:

```toml
[shell]
preset = "terminal" # or "minimal"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`.

## Versions

These tools come from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

Run these commands inside the VM:

| Command | Purpose |
| -- | -- |
| `rg` | Search file contents with ripgrep |
| `fd` | Find files by name |
| `fzf` | Select from a list with fuzzy search |
| `bat` | Read files with syntax highlighting |
| `eza` | List directory contents |
| `delta` | Read highlighted diffs |
| `jq` | Query JSON |
| `yq` | Query YAML with Mike Farah's yq, packaged as `yq-go` |
| `xh` | Send HTTP requests |
| `btop` | Inspect CPU, memory, and processes |
| `dust` | Inspect directory sizes |
| `duf` | Inspect filesystem space |
| `tldr` | Read command examples with tealdeer |

For example, search the current project and select a file:

```console
rg TODO .
fd --type f | fzf
```

Download tealdeer's command examples before first use:

```console
tldr --update
tldr tar
```

The update needs internet access and saves the pages in the VM user's cache.

## Git

The VM does not copy your Mac's commit identity. Set it once inside the VM:

```console
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Git writes these settings to `~/.gitconfig` in the persistent home of the VM
user, or to `~/.config/git/config` when that file already exists. Run the same
commands with `--local` inside a repository to use another identity there.
Authentication for private repositories belongs to the guest account too: an SSH
key mounted into the VM or a credential helper.

## Git diffs

Inside a Git repository, `git diff` and `git log -p` use delta when Git opens a
pager. Interactive staging uses delta's color-only filter. The settings are
written to the VM's system Git configuration; a repository or user Git
configuration can override them. bat, and delta through it, highlight in the
colors of the guest's theme. With the default `system` theme, `BAT_THEME=ansi`
uses the terminal's colors. Another theme sets `BAT_THEME=limanix`, a bat theme
built from its palette, and `BAT_CACHE_PATH` to the bat cache that holds it;
delta reads the same cache, and its added and removed lines take the palette's
green and red. A personal `bat cache --build` needs a `BAT_CACHE_PATH` of your
own, for example in the `[env]` table.

## Colors

The other tools draw in the guest's theme too. With the default `system` theme
they keep the terminal's own colors: fzf runs with `--color=16`, btop with its
`TTY` theme, and the rest with their defaults. Another theme gives each the
roles of its palette:

| Tool | Setting |
| -- | -- |
| fzf | `FZF_DEFAULT_OPTS` with the theme's `--color` |
| `ls`, eza, fd, dust and Zsh completion | `LS_COLORS`, generated with vivid |
| eza columns | `EZA_COLORS` |
| jq | `JQ_COLORS` |
| btop | Its default theme, `limanix`; a personal `btop.conf` keeps its own |
| Git status, branches and log decorations | `color.*` in the system Git configuration |
| `man` and `less` | `LESS_TERMCAP_*` and `GROFF_NO_SGR=1` |
| ripgrep | `RIPGREP_CONFIG_PATH` |
| tealdeer | `TEALDEER_CONFIG_DIR` |

Your own value in the `[env]` table of `limanix.toml`, or in a startup file,
replaces any of these variables; a repository or user Git configuration replaces
the colors of Git. yq, xh and duf keep their own colors: they take no colors
that a module could set system-wide.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Standard `programs.git.config` controls the default delta pager and interactive filter |
| Personal state | Git settings in `~/.gitconfig`; tealdeer pages in the user cache |
| Integration | Enables Git; part of both shell presets, usable without an editor or tmux |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Missing tldr pages | Run `tldr --update` once with network access |
| Missing commit identity | Set `user.name` and `user.email` in the guest; the Mac identity is not copied |
| Pager behaves differently | Check repository and user Git settings, which can override system defaults |
| System monitor | `btop` displays the guest workload; it does not monitor all Mac processes |
