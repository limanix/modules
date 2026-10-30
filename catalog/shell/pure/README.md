# Pure

[Pure](https://github.com/sindresorhus/pure) is a two-line Zsh prompt: the
directory and Git state above, the prompt symbol below. It draws in the colors
of the guest's theme.

## Select

Pure needs Zsh, which the `terminal` shell preset has; it is that preset's
default prompt:

```toml
[shell]
preset = "terminal"
prompt = "pure"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Pure.

## Versions

Pure comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

| Part | Shows |
| -- | -- |
| First line | The directory, the Git branch, a mark for uncommitted changes, arrows for commits to push or pull, and the duration of a command that ran longer than five seconds |
| Prompt symbol | `❯`, red after a failed command |
| Right side | Outside tmux, the words of `lmx status --short` that need attention, such as `restart`; inside tmux, its status line shows them |

## Colors

With the default `system` theme, Pure draws in the terminal's own colors.
Another theme in `[theme]` of `limanix.toml` sets the
`zstyle ':prompt:pure:*' color` settings from its palette: the directory in
`blue`, the branch in `purple`, the uncommitted mark in `orange`, the prompt
symbol in `green` and `red`. A terminal without 24-bit color gets the nearest of
256 colors.

Change a color or the right side in `~/.zshrc`, which Zsh reads after the
managed startup:

```zsh
zstyle ':prompt:pure:path' color cyan
RPROMPT='%*'   # replaces the lmx words with the time
```

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Zsh |
| Standard settings | An ordinary `programs.zsh.promptInit` assignment replaces Pure |
| Personal state | `~/.zshrc` |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Colors look wrong | `limanix shell` passes on `COLORTERM` when the terminal on the Mac sets it to `truecolor` or `24bit`. Without it, a palette theme gets the nearest of 256 colors: set `COLORTERM` in the Mac shell or in the `[env]` table, or choose colors from the 256-color palette with `zstyle`. The `system` theme needs neither |
| The login shell is Bash | Pure starts only in Zsh; choose a prompt that runs in Bash |
