# bash-git-prompt

[bash-git-prompt](https://github.com/magicmonty/bash-git-prompt) is a Bash
prompt on two lines: the last command's status, the directory and the Git state
above, the prompt symbol below. It draws in the colors of the guest's theme.

## Select

bash-git-prompt runs in Bash, the shell of the `minimal` preset:

```toml
[shell]
preset = "minimal"
prompt = "bash-git-prompt"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. The next `limanix shell` starts with bash-git-prompt.

## Versions

bash-git-prompt comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

| Part | Shows |
| -- | -- |
| Status | `✔` after a command that succeeded, `✘` and the status after one that failed |
| Directory and Git | The directory, the branch, arrows for commits to push or pull, and marks for staged, changed and untracked files |
| `lmx` words | Outside tmux, the words of `lmx status --short` that need attention, such as `restart`; inside tmux, its status line shows them |

The module turns off bash-git-prompt's periodic `git fetch`, which would reach
the network from every prompt in a repository: set
`GIT_PROMPT_FETCH_REMOTE_STATUS=1` in the `[env]` table to turn it on.

## Colors

With the default `system` theme, bash-git-prompt draws in the terminal's own
colors. Another theme in `[theme]` of `limanix.toml` gives each part the color
of its role: the directory in `blue`, the branch in `purple`, changes in
`orange`, a failure in `red`.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Shells | Bash |
| Standard settings | An ordinary `programs.bash.promptInit` assignment replaces bash-git-prompt |
| Personal state | `~/.git-prompt-colors.sh` replaces the managed colors; `prompt_callback` in `~/.bashrc` replaces the `lmx` words |
| Services and capabilities | Reads the guest's theme |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Another bash-git-prompt theme | Set `GIT_PROMPT_THEME` in the `[env]` table; `git_prompt_list_themes` lists the themes |
| The login shell is Zsh | bash-git-prompt starts only in Bash; choose a prompt that runs in Zsh |
