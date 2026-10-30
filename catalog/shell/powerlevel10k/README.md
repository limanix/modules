# Powerlevel10k

[Powerlevel10k](https://github.com/romkatv/powerlevel10k) is a fast Zsh prompt:
the directory and Git state on the left, the exit status, the duration of a slow
command and the tools a project uses on the right. It draws in the colors of the
guest's theme.

## Select

Powerlevel10k needs Zsh, which the `terminal` shell preset has:

```toml
[shell]
preset = "terminal"
prompt = "powerlevel10k"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Powerlevel10k.

## Versions

Powerlevel10k comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Its author keeps the project in limited
support: it works, without new features.

## Use

The module starts Powerlevel10k with its own lean style on two lines and plain
symbols, which every terminal font draws. Outside tmux, the right side also
shows the words of `lmx status --short` that need attention, such as `restart`;
inside tmux, its status line shows them.

`p10k configure` starts the Powerlevel10k wizard. It writes `~/.p10k.zsh` and
the line in `~/.zshrc` that loads it; that file then replaces the managed style,
colors included.

## Colors

With the default `system` theme, Powerlevel10k draws in the terminal's own
colors. Another theme in `[theme]` of `limanix.toml` gives each part the color
of its role: the directory in `blue`, a clean Git state in `green`, changes in
`yellow`, errors in `red`. A terminal without 24-bit color gets the nearest of
256 colors.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Zsh |
| Standard settings | An ordinary `programs.zsh.promptInit` assignment replaces Powerlevel10k |
| Personal state | `~/.p10k.zsh` from `p10k configure`, and `~/.zshrc` |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Icons from a Nerd Font | Run `p10k configure` and answer that your font draws the icons |
| Instant prompt | The managed style keeps it off; `p10k configure` can turn it on for your `~/.zshrc` |
| The login shell is Bash | Powerlevel10k starts only in Zsh; choose a prompt that runs in Bash |
