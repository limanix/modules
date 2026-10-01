# Yazi

Installs Yazi, a terminal file manager, with the preview and search dependencies included by its Nixpkgs package.

```toml
[nixos]
modules = ["lmx:yazi"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Yazi comes from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.
Inside the VM, `yazi --version` shows the installed version.

## Use

Inside the VM, run Yazi from the directory you want to browse:

```console
yazi
```

It shows directories, file lists, and previews in the terminal.
Files you edit or delete are the files in that directory, including files shared from your Mac.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the base Nixpkgs Yazi package with its packaged preview/search dependencies | `check.nix` |
