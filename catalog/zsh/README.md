# Zsh

Makes Zsh the VM user's login shell and configures command completion, a prompt,
searchable local history, directory navigation, and project environments.

```toml
[nixos]
modules = ["lmx:zsh"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
The next `limanix shell` uses Zsh.

## Versions

All tools come from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `zsh --version` shows the shell version.

## Use

| Tool | Behavior inside the VM |
| --- | --- |
| Zsh autosuggestions | Suggests commands from shell history; press Right to accept |
| Zsh syntax highlighting | Highlights commands as you type |
| fzf-tab and Carapace | Press Tab to search completion candidates |
| fzf | Ctrl-T inserts selected paths; Alt-C changes directory; Ctrl-R remains assigned to Atuin |
| Starship | Shows the VM hostname, directory, Git state, detected language versions, and failed command status |
| Atuin | Press Ctrl-R to search recorded commands; Up retains shell history navigation |
| zoxide | After visiting directories, use `z project` or `zi` to find them again |
| direnv and nix-direnv | Loads an approved project environment when you enter its directory |

The VM platform supplies Ghostty's terminal description for connections with `TERM=xterm-ghostty`.
The Carapace initialization script is generated during the Nix build and sourced
when Zsh starts.

Atuin records history in the VM user's data directory, normally
`~/.local/share/atuin/history.db`. Automatic synchronization and update checks are
disabled; no account is needed. Its managed settings are in `/etc/atuin/config.toml`.

For a project that already has an `.envrc`, inspect that file and run this inside
the project directory in the VM:

```console
direnv allow
```

Direnv requires approval again when `.envrc` changes. For Nix projects, nix-direnv
provides cached `use flake` and `use nix` environments. This module does not create
an environment definition for the project.

## Customize

Add personal shell settings to `~/.zshrc` inside the VM. A personal
`~/.config/starship.toml` takes precedence over the module's prompt settings.
To change managed settings, use a [custom NixOS module](../../guides/writing-modules.md).

Zsh is the suggested login shell. To keep the Zsh tools while choosing a different
login shell, set `limanix.user.shell` in a custom module. For example:

```nix
{ pkgs, ... }:
{
  limanix.user.shell = pkgs.bashInteractive;
}
```

The [tmux module](../tmux/README.md) adds persistent terminal sessions.
The [console module](../console/README.md) combines the shell, sessions, editor,
and command-line tools.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Makes Zsh the suggested login shell; an ordinary `limanix.user.shell` assignment can choose another shell | `check.nix`, `checks/contracts.nix`: zshShell |
| Generates and sources Carapace initialization, fzf-tab, autosuggestions and highlighting | `check.nix`, `smoke.nix`: startup |
| Ctrl-R is assigned to Atuin; fzf path selection and zoxide/direnv hooks are available | `smoke.nix`: startup |
| Starship shows the hostname and failed status; Atuin synchronization and update checks default off and accept ordinary overrides | `check.nix`, `checks/contracts.nix`, `smoke.nix`: startup |
| Personal `.zshrc` settings remain available after system startup | `smoke.nix`: startup |
