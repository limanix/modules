# Spaceship

[Spaceship](https://spaceship-prompt.sh) is a Zsh prompt: the directory, Git
state and the versions of the tools a project uses on the first line, the prompt
symbol on the second. It draws in the colors of the guest's theme.

## Select

Spaceship needs Zsh, which the `terminal` shell preset has:

```toml
[shell]
preset = "terminal"
prompt = "spaceship"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Spaceship.

## Versions

Spaceship comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

| Part | Shows |
| -- | -- |
| First line | The user and host over SSH, the directory, the Git branch and status, the versions of the languages a project uses and how long a slow command ran |
| Prompt symbol | `➜`, red after a failed command |
| Right side | Outside tmux, the words of `lmx status --short` that need attention, such as `restart`; inside tmux, its status line shows them |

The module replaces the three symbols of Spaceship that need a Nerd Font, such
as the Git branch icon, with plain text.

## Colors

With the default `system` theme, Spaceship draws in the terminal's own colors.
Another theme in `[theme]` of `limanix.toml` sets every `SPACESHIP_*_COLOR` from
its palette: each section keeps its color's role, such as the directory in
`cyan` and the branch in `purple`. A terminal without 24-bit color gets the
nearest of 256 colors.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Zsh |
| Standard settings | An ordinary `programs.zsh.promptInit` assignment replaces Spaceship |
| Personal state | `~/.spaceshiprc.zsh`, read after the managed settings, changes any of them |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Icons from a Nerd Font | Set the `SPACESHIP_*_SYMBOL` settings in `~/.spaceshiprc.zsh` |
| The login shell is Bash | Spaceship starts only in Zsh; choose a prompt that runs in Bash |
