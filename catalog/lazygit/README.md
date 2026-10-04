# Lazygit

Installs Lazygit, a terminal interface for Git, and enables the
[Git module](../git/README.md).

```toml
[nixos]
modules = ["lmx:lazygit"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Lazygit comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `lazygit --version` shows the
installed version.

## Use

Inside the VM, open a Git repository and run:

```console
lazygit
```

The interface lets you inspect changes, stage files, and work with commits and
branches. Configure your commit identity as described in the
[Git module](../git/README.md#use).

## Customize

The managed configuration uses Catppuccin Mocha in
`/etc/xdg/lazygit/config.yml`. A personal `~/.config/lazygit/config.yml` takes
precedence through Lazygit's native XDG lookup. Project `.lazygit.yml` and
`.git/lazygit.yml` settings retain their native precedence. To change managed
settings, assign `programs.lazygit.settings` in a custom NixOS module:

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
| Personal configuration | `~/.config/lazygit/config.yml`; project `.lazygit.yml` and `.git/lazygit.yml` |
| Integration | Imports Git; AstroNvim opens the same Lazygit application |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Directory is not a Git repository | Open the project repository before starting Lazygit |
| Personal theme wins | Native personal and project configuration precedence remains active |
| Authentication or identity | Configure Git credentials and commit identity for the guest account |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Lazygit and Git are enabled and their installed commands run | `eval.defaults`, `run.commands` |
| All managed theme and author colors use the Mocha palette | `eval.defaults` |
| An ordinary user setting replaces a managed theme color | `eval.themeOverride` |
