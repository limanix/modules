# Lazygit

Installs Lazygit, a terminal interface for Git, and enables the [Git module](../git/README.md).

```toml
[nixos]
modules = ["lmx:lazygit"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Lazygit comes from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.
Inside the VM, `lazygit --version` shows the installed version.

## Use

Inside the VM, open a Git repository and run:

```console
lazygit
```

The interface lets you inspect changes, stage files, and work with commits and branches.
Configure your commit identity as described in the [Git module](../git/README.md#use).

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs Lazygit and enables Git | `check.nix` |
| Selecting Git again preserves the system and public settings | `checks/contracts.nix`: composition |
