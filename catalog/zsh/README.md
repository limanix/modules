# Zsh

Makes Zsh the VM user's login shell and configures Oh My Zsh, command
completion, a prompt, searchable local history, directory navigation, and
project environments.

```toml
[nixos]
modules = ["lmx:zsh"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
The next `limanix shell` uses Zsh. A fresh home opens the configured shell
directly without the automatic first-login setup wizard. The module does not
create or edit personal `.zshenv`, `.zprofile`, `.zshrc` or `.zlogin` files.
Personal startup files, `ZDOTDIR` and an existing new-user setup handler retain
their normal behavior.

## Versions

Oh My Zsh and the other tools come from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `zsh --version` shows the shell
version.

## Use

| Tool                    | Behavior inside the VM                                                                             |
| ----------------------- | -------------------------------------------------------------------------------------------------- |
| Oh My Zsh               | Loads the shell framework; Starship supplies the prompt                                            |
| Zsh autosuggestions     | Suggests commands from shell history; press Right to accept                                        |
| Zsh syntax highlighting | Highlights commands as you type                                                                    |
| fzf-tab and Carapace    | Press Tab to search completion candidates                                                          |
| fzf                     | Ctrl-T inserts selected paths; Alt-C changes directory; Ctrl-R remains assigned to Atuin           |
| Starship                | Shows the VM hostname, directory, Git state, detected language versions, and failed command status |
| Atuin                   | Press Ctrl-R to search recorded commands; Up retains shell history navigation                      |
| zoxide                  | After visiting directories, use `z project` or `zi` to find them again                             |
| direnv and nix-direnv   | Loads an approved project environment when you enter its directory                                 |

The VM platform supplies Ghostty's terminal description for connections with
`TERM=xterm-ghostty`. The Carapace initialization script is generated during the
Nix build and sourced when Zsh starts.

Atuin records history in the VM user's data directory, normally
`~/.local/share/atuin/history.db`. Automatic synchronization and update checks
are disabled; no account is needed. Its managed settings are in
`/etc/atuin/config.toml`.

For a project that already has an `.envrc`, inspect that file and run this
inside the project directory in the VM:

```console
direnv allow
```

Direnv requires approval again when `.envrc` changes. For Nix projects,
nix-direnv provides cached `use flake` and `use nix` environments. This module
does not create an environment definition for the project.

## Customize

Add personal shell settings to `~/.zshrc` inside the VM. A personal
`~/.config/starship.toml` takes precedence over the module's prompt settings.
The managed prompt uses the Catppuccin Mocha palette. Its palette and module
styles accept ordinary `programs.starship.settings` assignments. To change
managed settings, use a [custom NixOS module](../../guides/writing-modules.md).

For example, enable Oh My Zsh's Git aliases with this custom module:

```nix
{ ... }:
{
  programs.zsh.ohMyZsh.plugins = [ "git" ];
}
```

Zsh is the suggested login shell. To keep the Zsh tools while choosing a
different login shell, set `limanix.user.shell` in a custom module. For example:

```nix
{ pkgs, ... }:
{
  limanix.user.shell = pkgs.bashInteractive;
}
```

The [tmux module](../tmux/README.md) adds persistent terminal sessions. The
[console module](../console/README.md) combines the shell, sessions, editor, and
command-line tools.

## Configuration and integration

| Boundary                  | Contract                                                                                        |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| Public setting            | `limanix.user.shell` accepts a different login shell                                            |
| Standard settings         | `programs.zsh.*`, `programs.starship.settings`, `programs.atuin.*` and the tools' NixOS options |
| Personal state            | `~/.zshrc`, native XDG configuration, Atuin history and project direnv state                    |
| Integration               | Supplies shell hooks; Yazi adds its directory handoff independently                             |
| Services and capabilities | No language-support provider declarations; Atuin synchronization defaults off                   |

## Corner cases

| Case                               | Behavior or next step                                                                          |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| Project environment is blocked     | Inspect `.envrc` and run `direnv allow` in the guest                                           |
| History is not shared with the Mac | Atuin uses guest-local state and does not sync by default                                      |
| Different login shell              | Zsh integrations apply when you run Zsh; changing the login shell does not remove its packages |
| Pristine home                      | The managed shell starts without creating `~/.zshrc` or opening the setup wizard               |
| Custom startup directory           | Zsh reads personal startup files from `ZDOTDIR` when set                                       |
| You want the setup wizard          | The normal `zsh-newuser-install` function remains available for explicit manual use            |

## Guarantees

| Guarantee                                                                                                  | Checked by                                         |
| ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Suggests Zsh as the account shell; an ordinary `limanix.user.shell` assignment can choose another shell    | `eval.defaults`, `eval.shell`                      |
| Managed startup loads Oh My Zsh, Carapace, fzf-tab, autosuggestions and highlighting                       | `eval.defaults`, `run.startup`                     |
| Managed startup keeps Tab completion, Atuin Ctrl-R, fzf Ctrl-T, zoxide and direnv hooks available together | `run.startup`, `vm.activation`                     |
| Managed Starship settings use Mocha, show the hostname and failed status, and accept ordinary overrides    | `eval.preferences`, `run.startup`                  |
| Atuin synchronization and update checks default off and accept ordinary overrides                          | `eval.defaults`, `eval.preferences`, `run.startup` |
| Fresh and repeat logins skip the automatic wizard without creating personal startup files                  | `run.startup`, `vm.activation`                     |
| Personal startup settings, custom `ZDOTDIR` and an existing new-user handler remain unchanged              | `run.startup`, `vm.activation`                     |
| The activated account uses Zsh and reads its installed global startup files                                | `vm.activation`                                    |
