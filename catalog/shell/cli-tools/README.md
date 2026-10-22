# CLI tools

Installs tools for finding files, reading code and data, making HTTP requests,
and inspecting the VM. Also enables Git and configures delta as its diff pager.

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
configuration can override them. With the default `system` theme flavor,
`BAT_THEME=ansi` makes bat, and delta through it, highlight in the terminal's
colors.

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

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Installs the listed tools, enables Git and runs their commands | `eval.packages`, `run.commands` |
| Generated Git settings select delta for paging and interactive diffs | `eval.gitDefaults`, `run.gitConfig` |
| Ordinary NixOS and personal Git settings can replace the pager defaults | `eval.gitOverrides`, `run.gitConfig` |
| bat and delta use the terminal's colors with the system flavor only | `eval.terminalColors` |
