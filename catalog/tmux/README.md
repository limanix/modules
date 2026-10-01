# Tmux

Adds terminal windows and split panes, mouse support, vi copy mode, OSC 52 clipboard
support, and saved sessions through tmux-resurrect and tmux-continuum.

```toml
[nixos]
modules = ["lmx:tmux"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Guarantees

| Guarantee | Covered by |
|---|---|
| `tmux` and the resurrect/continuum plugins are installed; vi mode, `tmux-256color`, and a 10 ms escape delay are defaults | `check.nix`, `smoke.nix`: configuration |
| Ordinary assignments can replace `programs.tmux.keyMode`, `programs.tmux.terminal`, and `programs.tmux.escapeTime` | `tests.nix`: preferences; `smoke.nix`: configuration |
| Ctrl/Alt-H/J/K/L move and resize panes; prefix followed by Ctrl-H/J/K/L forwards the control key; panes marked by smart-splits receive their navigation keys | `smoke.nix`: configuration |
| `lmx.tmux.navigation.enable = false` removes the custom navigation and forwarding bindings while retaining mouse, clipboard, copy mode, and restoration plugins | `tests.nix`: navigation; `smoke.nix`: configuration |
| In vi copy mode, `v` begins a selection and `y` copies it; tmux emits OSC 52 clipboard output for supported terminals | `smoke.nix`: configuration |
| Ctrl-B, Ctrl-S saves sessions, panes and working directories under `~/.tmux/resurrect/`; Ctrl-B, Ctrl-R and continuum restore the saved layout | `smoke.nix`: configuration |
| Continuum is configured to save every 15 minutes through its status-line hook | `smoke.nix`: configuration |
| Selecting `lmx:tmux` provides named sessions for `limanix shell --session` without attaching ordinary shells | `check.nix`, `smoke.nix`: sessions |
| The session provider creates a session, reattaches to the same session, and preserves literal names without executing their contents | `smoke.nix`: sessions |

## Versions

Tmux and its plugins come from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `tmux -V` shows the installed version.

## Use

Inside the VM, create or attach to a named session:

```console
tmux new-session -A -s work
```

The module provides the guest session interface used by `limanix shell --session`.
Create or attach to that session directly from the Mac:

```console
limanix shell <name> --session work
```

Tmux starts only when you run it. The prefix is Ctrl-B: press it, release it, then
press the second key.

| Keys | Action |
| --- | --- |
| Ctrl-B, `c` | New window |
| Ctrl-B, `%` / `"` | Split left/right or top/bottom |
| Ctrl-B, `w` | Choose a window |
| Ctrl-B, `d` | Detach from the session |
| Ctrl-B, `[` | Enter copy mode; `v` selects and `y` copies |
| Ctrl-H/J/K/L | Move left/down/up/right between panes |
| Ctrl-B, Ctrl-H/J/K/L | Send the original control key to the application |
| Alt-H/J/K/L | Resize a pane |
| Ctrl-B, Ctrl-S | Save the current layout |
| Ctrl-B, Ctrl-R | Restore the last saved layout |
| Ctrl-B, `?` | Show tmux bindings |

With [AstroNvim](../astronvim/README.md), movement and resize keys also navigate
editor splits through smart-splits.nvim. In tmux these keys replace their usual
shell actions, including Ctrl-L to clear the screen. The Mac terminal must send
Option as Alt for the resize bindings. Use Ctrl-B, Ctrl-L to clear the screen,
Ctrl-B, Ctrl-K to delete to the end of the line, or Ctrl-B, Ctrl-H to delete a
character in shells with those bindings.

To retain the shell's Ctrl/Alt-H/J/K/L bindings, disable the pane navigation
bindings in a [custom NixOS module](../../guides/writing-modules.md):

```nix
{
  lmx.tmux.navigation.enable = false;
}
```

This also disables the prefix forwarding bindings. Mouse support, clipboard,
copy mode, and session saving remain enabled. The defaults for
`programs.tmux.keyMode`, `programs.tmux.terminal`, and `programs.tmux.escapeTime`
can also be overridden by ordinary assignments in a custom module.

## Clipboard and color

Use a terminal on the Mac with truecolor and OSC 52 clipboard support.
The VM's platform base supplies Ghostty's terminal description for `TERM=xterm-ghostty`.
The module enables these capabilities for `xterm*` terminals; other terminal types use tmux's capability detection. Some terminals require enabling clipboard access in their
settings. Copying a selection sends it through the terminal connection to the
Mac clipboard. Paste from the Mac with the terminal's normal paste shortcut.

See [tmux's clipboard guide](https://github.com/tmux/tmux/wiki/Clipboard) for
terminal-specific settings. A `pbcopy` command inside the Linux VM does not provide
access to the Mac clipboard.

## Resume after a VM restart

Continuum saves every 15 minutes while tmux's status line is active. Before
`limanix update`, save with Ctrl-B, Ctrl-S and wait for the save to finish. Files
are stored in `~/.tmux/resurrect/` inside the VM. Start tmux after reconnecting;
continuum restores the latest snapshot when the tmux server starts.

The snapshot includes sessions, windows, pane layout, and working directories.
Resurrect restarts its upstream default list of programs, such as editors, pagers,
and terminal monitors. It does not preserve running processes or unsaved editor
buffers. Development servers and test commands need to be started again.
See [the supported program list](https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_programs.md).

Personal overrides belong in `~/.tmux.conf` inside the VM. Keep the status line
enabled and preserve continuum's `status-right` hook if you customize it.
