# Zsh

Makes Zsh the VM user's login shell and configures Oh My Zsh, command
completion, a prompt, searchable local history, directory navigation, and
project environments.

## Select

The `terminal` shell preset includes Zsh, and `prompt` chooses its prompt:

```toml
[shell]
preset = "terminal"
prompt = "pure" # pure, starship or none
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
| Prompt | Pure by default: directory, Git state, command duration and a failed command's color; Starship with `prompt = "starship"` adds the hostname, detected language versions and the exit status |
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
settings. To keep them, start from a copy:

```console
install -D -m 644 /etc/atuin/config.toml ~/.config/atuin/config.toml
```

For a project that already has an `.envrc`, inspect that file and run this
inside the project directory in the VM:

```console
direnv allow
```

Direnv requires approval again when `.envrc` changes. For Nix projects,
nix-direnv provides cached `use flake` and `use nix` environments. This module
does not create an environment definition for the project.

## Prompt

Both managed prompts use the colors of the guest's theme. With the default
`system` flavor they are the terminal's own colors. The prompt follows the theme
of the terminal on your Mac. A Catppuccin flavor in `[theme]` of `limanix.toml`
uses its palette instead. Outside tmux, both show the words of
`lmx status --short` that need attention, such as `restart`; inside tmux, tmux's
status line shows them.

| `prompt` | Behavior |
| -- | -- |
| `pure` | [Pure](https://github.com/sindresorhus/pure) on two lines. Its colors are `zstyle ':prompt:pure:*' color` settings; a terminal without 24-bit color gets the nearest of 256 colors. The `lmx` words appear in the right prompt |
| `starship` | Starship with the theme's palette, the hostname and the exit status. A personal `~/.config/starship.toml` takes precedence; managed settings accept ordinary `programs.starship.settings` assignments, including the `lmx` segment, `custom.lmx` |
| `none` | No managed prompt: set `PROMPT` in your `~/.zshrc` |

With Pure, change a color or the right prompt in `~/.zshrc`, which Zsh reads
after the managed startup:

```zsh
zstyle ':prompt:pure:path' color cyan
RPROMPT='%*'   # replaces the lmx words with the time
```

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

The module's public setting `lmx.zsh.prompt` takes the values of `prompt`. An
ordinary `programs.zsh.promptInit` assignment replaces the managed Pure or empty
prompt initialization.

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
| Public settings | `lmx.zsh.prompt`: `pure`, `starship` or `none`; `limanix.user.shell` accepts a different login shell |
| Standard settings | `programs.zsh.*`, `programs.starship.settings`, `programs.atuin.*` and the tools' NixOS options |
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
| Colors look wrong with Pure | With a Catppuccin flavor, set `COLORTERM=truecolor` when the terminal supports 24-bit color, or choose colors from its 256-color palette with `zstyle`; the `system` flavor needs neither |
