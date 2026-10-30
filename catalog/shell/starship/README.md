# Starship

[Starship](https://starship.rs) is a prompt for Bash and Zsh. It shows the
directory, Git state, the hostname, the versions of the languages a project uses
and the exit status of a failed command, in the colors of the guest's theme.

## Select

```toml
[shell]
prompt = "starship"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Starship, in Zsh or
in Bash.

## Versions

Starship comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Inside the VM, `starship --version` shows the
version.

## Use

| Part | Shows |
| -- | -- |
| Prompt | The hostname, the directory, the Git branch and status, the language versions a project uses and how long a slow command ran |
| Exit status | The status of the last command when it failed |
| `lmx` words | Outside tmux, the words of `lmx status --short` that need attention, such as `restart`; inside tmux, its status line shows them |

`starship explain` describes each part of the current prompt. The managed
settings replace the symbols of Starship that need a Nerd Font, such as the Git
branch icon, with plain text.

## Colors

With the default `system` theme, Starship draws in the terminal's own colors.
Another theme in `[theme]` of `limanix.toml` gives Starship its palette, a
`palettes.<theme>` table with the theme's roles, so styles such as `bold blue`
or `accent` name its colors.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Bash and Zsh |
| Standard settings | `programs.starship.settings` accepts ordinary assignments, including the `lmx` segment, `custom.lmx` |
| Personal state | A personal `~/.config/starship.toml` replaces the managed settings |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| A personal `starship.toml` | It replaces every managed setting, the palette and the `lmx` segment too; copy them from `starship print-config` |
