# CLI tools

Installs tools for finding files, reading code and data, making HTTP requests, and inspecting the VM.
Also enables [Git](../git/README.md) and configures delta as its diff pager.

```toml
[nixos]
modules = ["lmx:cli-tools"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

These tools come from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.

## Use

Run these commands inside the VM:

| Command | Purpose |
|---------|---------|
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

## Git diffs

Inside a Git repository, `git diff` and `git log -p` use delta when Git opens a pager.
Interactive staging uses delta's color-only filter.
The settings are written to the VM's system Git configuration; a repository or user Git configuration can override them.

## Configuration and integration

| Boundary | Contract |
|---|---|
| Settings | Standard `programs.git.config` controls the default delta pager and interactive filter |
| Personal state | Git settings in `~/.gitconfig`; tealdeer pages in the user cache |
| Integration | Imports Git; tools remain usable without Console or an editor |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
|---|---|
| Missing tldr pages | Run `tldr --update` once with network access |
| Pager behaves differently | Check repository and user Git settings, which can override system defaults |
| System monitor | `btop` displays the guest workload; it does not monitor all Mac processes |

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs every command listed in Use and enables Git | `check.nix` |
| Generated Git settings select delta for paging and interactive diff filtering | `check.nix`, `smoke.nix`: gitConfig |
| Users may replace the pager/filter defaults through NixOS settings or personal Git configuration | `tests.nix`, `smoke.nix`: gitConfig |
| Selecting Git again preserves the system and public settings | `tests.nix`: composition |
