# Liquidprompt

[Liquidprompt](https://github.com/liquidprompt/liquidprompt) is an adaptive
prompt for Bash and Zsh: it shows what matters where you are, such as Git state,
background jobs, a high load or the last error code, and hides the rest. It
draws in the colors of the guest's theme.

## Select

```toml
[shell]
prompt = "liquidprompt"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with Liquidprompt, in
Zsh or in Bash.

## Versions

Liquidprompt comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

Liquidprompt adds a part only when it has something to say: the Git branch and
changes in a repository, the number of background jobs, the load of a busy
machine, the status of a failed command. Outside tmux, the words of
`lmx status --short` that need attention, such as `restart`, stand before the
prompt mark; inside tmux, its status line shows them.

`prompt_tag NAME` puts a word in front of the prompt, and `prompt_off` and
`prompt_on` turn Liquidprompt off and on for the current shell.

## Colors

With the default `system` theme, Liquidprompt draws in the terminal's own
colors. Another theme in `[theme]` of `limanix.toml` writes
`/etc/liquidpromptrc`, which recomputes every default color of Liquidprompt from
the theme's palette: the colors it names red, green or blue become the roles of
the same name.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Bash and Zsh |
| Standard settings | An ordinary `programs.bash.promptInit` or `programs.zsh.promptInit` assignment replaces Liquidprompt in that shell |
| Personal state | `~/.config/liquidpromptrc` or `~/.liquidpromptrc` replaces `/etc/liquidpromptrc`, colors included |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Keep the theme's colors in your own settings | Start your `~/.config/liquidpromptrc` from a copy of `/etc/liquidpromptrc` |
| Colors look wrong | A palette theme needs a terminal with 24-bit color; the `system` theme does not |
