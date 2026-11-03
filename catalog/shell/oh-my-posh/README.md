# Oh My Posh

[Oh My Posh](https://ohmyposh.dev) is a prompt for Bash and Zsh. The module
starts it with its own settings on two lines: the user and host, the directory,
Git state and the duration of a slow command above, the prompt symbol below. It
draws in the colors of the guest's theme.

## Select

```toml
[shell]
prompt = "oh-my-posh"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Oh My Posh, in Zsh
or in Bash.

## Versions

Oh My Posh comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Inside the VM, `oh-my-posh version` shows the
version.

## Use

| Part | Shows |
| -- | -- |
| First line | `user@host`, the directory, the Git branch with `*` for uncommitted changes and arrows for commits to push or pull, and how long a command over five seconds ran |
| `lmx` words | Outside tmux, the words of `lmx status --short` that need attention, such as `restart`; inside tmux, its status line shows them |
| Prompt symbol | `❯`, red after a failed command |

The managed settings use plain symbols, which every terminal font draws.

## Colors

With the default `system` theme, Oh My Posh draws in the terminal's own colors.
Another theme in `[theme]` of `limanix.toml` becomes the settings' `palette`,
with one entry per role, and each part names its role, such as `p:blue` for the
directory.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Bash and Zsh |
| Standard settings | An ordinary `programs.bash.promptInit` or `programs.zsh.promptInit` assignment replaces Oh My Posh in that shell |
| Personal state | `POSH_THEME`, set in the `[env]` table, names your own settings file; the managed `palette` does not apply to it |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| A theme from the Oh My Posh gallery | Save its file in your home and set `POSH_THEME` to it; most gallery themes need a Nerd Font |
| Colors look wrong | A palette theme needs a terminal with 24-bit color; the `system` theme does not |
