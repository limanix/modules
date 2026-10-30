# Zsh

Makes Zsh the VM user's login shell and configures Oh My Zsh, command
completion, searchable local history, directory navigation, and project
environments.

## Select

The `terminal` shell preset includes Zsh. `prompt` chooses one of the catalog's
prompts, such as [Pure](../pure/README.md); `none` leaves the prompt to your
`~/.zshrc`:

```toml
[shell]
preset = "terminal"
prompt = "pure"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` uses Zsh. A fresh home opens
the configured shell directly without the automatic first-login setup wizard.
The module does not create or edit personal `.zshenv`, `.zprofile`, `.zshrc` or
`.zlogin` files. Personal startup files, `ZDOTDIR` and an existing new-user
setup handler retain their normal behavior.

## Versions

Oh My Zsh and the other tools come from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Inside the VM, `zsh --version` shows the shell
version.

## Use

| Tool | Behavior inside the VM |
| -- | -- |
| Oh My Zsh | Loads the shell framework; the chosen prompt replaces its themes |
| Zsh autosuggestions | Suggests commands from shell history; press Right to accept |
| Zsh syntax highlighting | Highlights commands as you type |
| fzf-tab and Carapace | Press Tab to search completion candidates |
| fzf | Ctrl-T inserts selected paths; Alt-C changes directory; Ctrl-R remains assigned to Atuin |
| Atuin | Press Ctrl-R to search recorded commands; Up retains shell history navigation |
| zoxide | After visiting directories, use `z project` or `zi` to find them again |
| direnv and nix-direnv | Loads an approved project environment when you enter its directory |

The VM platform supplies Ghostty's terminal description for connections with
`TERM=xterm-ghostty`. The Carapace initialization script is generated during the
Nix build and sourced when Zsh starts.

Atuin records history in the VM user's data directory, normally
`~/.local/share/atuin/history.db`. Automatic synchronization and update checks
are disabled; no account is needed. Its managed settings are in
`/etc/atuin/config.toml`. Atuin reads only one `config.toml`: a personal
`~/.config/atuin/config.toml` replaces the managed file, with both disabled
settings. To keep them, start from a copy, with the theme it names:

```console
install -D -m 644 /etc/atuin/config.toml ~/.config/atuin/config.toml
cp -r /etc/atuin/themes ~/.config/atuin/
```

With a theme other than `system` in `[theme]` of `limanix.toml`, the command
highlighting, the autosuggestions and Atuin's search draw in its palette; the
`system` theme leaves them in the terminal's colors.

For a project that already has an `.envrc`, inspect that file and run this
inside the project directory in the VM:

```console
direnv allow
```

Direnv requires approval again when `.envrc` changes. For Nix projects,
nix-direnv provides cached `use flake` and `use nix` environments. This module
does not create an environment definition for the project.

## Customize

Add personal shell settings to `~/.zshrc` inside the VM. To change managed
settings, use a [custom NixOS module](https://docs.limanix.dev/modules/custom).
For example, enable Oh My Zsh's Git aliases:

```nix
{ ... }:
{
  programs.zsh.ohMyZsh.plugins = [ "git" ];
}
```

An ordinary `programs.zsh.promptInit` assignment replaces the prompt that a
prompt module starts.

Zsh is the suggested login shell. To keep the Zsh tools while choosing a
different login shell, set `limanix.user.shell` in a custom module. For example:

```nix
{ pkgs, ... }:
{
  limanix.user.shell = pkgs.bashInteractive;
}
```

With `multiplexer = "tmux"`, the [tmux module](../tmux/README.md) adds
persistent terminal sessions.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public settings | `limanix.user.shell` accepts a different login shell |
| Standard settings | `programs.zsh.*`, `programs.atuin.*` and the tools' NixOS options |
| Personal state | `~/.zshrc`, native XDG configuration, Atuin history and project direnv state |
| Integration | Supplies shell hooks; Yazi adds its directory handoff independently |
| Services and capabilities | No language-support provider declarations; Atuin synchronization defaults off |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Project environment is blocked | Inspect `.envrc` and run `direnv allow` in the guest |
| History is not shared with the Mac | Atuin uses guest-local state and does not sync by default |
| Different login shell | Zsh integrations apply when you run Zsh; changing the login shell does not remove its packages |
| Pristine home | The managed shell starts without creating `~/.zshrc` or opening the setup wizard |
| Custom startup directory | Zsh reads personal startup files from `ZDOTDIR` when set |
| You want the setup wizard | The normal `zsh-newuser-install` function remains available for explicit manual use |
