# Git

Enables Git, the version control system, through the NixOS `programs.git`
option.

```toml
[nixos]
modules = ["lmx:git"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Git comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `git --version` shows the
installed version.

## Use

The module does not configure your commit identity. Set it once inside the VM:

```console
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Git saves these settings in `~/.gitconfig` in the VM user's home directory. To
use another identity in one repository, run the same commands with `--local`
instead of `--global` inside that repository.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `programs.git.*`; personal identity and preferences in `~/.gitconfig` |
| Integration | Imported by CLI tools and Lazygit; repeated entry-point imports configure Git once |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Missing commit identity | Set `user.name` and `user.email` in the guest; the module does not copy the Mac identity |
| Private repository access | Configure authentication for the guest account; installing Git does not authorize access |
| Shared repositories | Changes in a read-write project mount affect the Mac files |

## Guarantees

| Guarantee | Covered by |
| -- | -- |
| Enables Git and installs the configured NixOS Git package | `check.nix` |
