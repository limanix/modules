# GitHub CLI

Installs `gh`, the GitHub command-line client.

```toml
[nixos]
modules = ["lmx:gh"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

GitHub CLI comes from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.
Inside the VM, `gh --version` shows the installed version.

## Use

Authenticate from inside the VM and check the account:

```console
gh auth login
gh auth status
```

Then, inside a repository, `gh pr list` lists its pull requests and `gh issue list` lists its issues.
For commands that use local Git, select [Git](../git/README.md) as well.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the base Nixpkgs GitHub CLI package providing `gh` | `check.nix` |
