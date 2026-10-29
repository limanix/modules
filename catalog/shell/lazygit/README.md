# Lazygit

Installs Lazygit, a terminal interface for Git, and enables Git.

## Select

The `terminal` shell preset includes Lazygit; there is no selector for it:

```toml
[shell]
preset = "terminal"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`.

## Versions

Lazygit comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Inside the VM, `lazygit --version` shows the
installed version.

## Use

Inside the VM, open a Git repository and run:

```console
lazygit
```

The interface lets you inspect changes, stage files, and work with commits and
branches. Press Space to stage a file, `c` to commit, `P` to push, `p` to pull
and `?` to see the keys. Configure your commit identity as described in
[CLI tools](../cli-tools/README.md#git).

## Customize

With the default `system` flavor, Lazygit keeps its own theme, which uses the
terminal's colors and background. A Catppuccin flavor in `[theme]` of
`limanix.toml` sets the colors of its palette in `/etc/xdg/lazygit/config.yml`.
Lazygit reads only the first `config.yml` it finds: a personal
`~/.config/lazygit/config.yml` replaces the managed file, with the clipboard
command and any Catppuccin colors it sets. To keep them, start from a copy:

```console
install -D -m 644 /etc/xdg/lazygit/config.yml ~/.config/lazygit/config.yml
```

Project `.lazygit.yml` and `.git/lazygit.yml` settings retain their native
precedence. To change managed settings, assign `programs.lazygit.settings` in a
custom NixOS module:

```nix
{ ... }:
{
  programs.lazygit.settings.gui.theme.activeBorderColor = [ "cyan" "bold" ];
}
```

The package is configurable with `programs.lazygit.package`.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `programs.lazygit.package` and `programs.lazygit.settings` |
| Managed configuration | `/etc/xdg/lazygit/config.yml` |
| Personal configuration | `~/.config/lazygit/config.yml`, which replaces the managed file; project `.lazygit.yml` and `.git/lazygit.yml` |
| Integration | Enables Git; AstroNvim opens the same Lazygit application |
| Clipboard | Copy commands send text to the Mac clipboard through the platform's `pbcopy`; see [Terminal and clipboard](https://docs.limanix.dev/inside/clipboard) |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Directory is not a Git repository | Open the project repository before starting Lazygit |
| Personal theme wins | Native personal and project configuration precedence remains active |
| Authentication or identity | Configure Git credentials and commit identity for the guest account |
