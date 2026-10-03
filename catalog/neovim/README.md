# Neovim

Enables the Neovim text editor through the NixOS `programs.neovim` option.

```toml
[nixos]
modules = ["lmx:neovim"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Neovim comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `nvim --version` shows the
installed version.

## Use

Inside the VM, open a file with the `nvim` command:

```console
nvim notes.md
```

The `vi` and `vim` aliases also launch Neovim.

## Make Neovim the default editor

The module leaves `EDITOR` at its NixOS default, `nano`. To make Neovim the
editor for programs that read `EDITOR`, such as `git commit`, keep `lmx:neovim`
selected and add a [custom module](../../guides/writing-modules.md) with this
setting:

```nix
{
  programs.neovim.defaultEditor = true;
}
```

## Language servers

The module does not configure Neovim's LSP client. To use `gopls` from the
[Go module](../go/README.md) or `rust-analyzer` from the
[Rust module](../rust/README.md), configure
[Neovim's LSP client](https://neovim.io/doc/user/lsp/) to start the server.
[Editor integration](../../guides/catalog.md#editor-integration) describes the
options.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `programs.neovim.*`, including package, aliases and default editor |
| Personal state | `~/.config/nvim/`, plus native XDG data, state and cache directories |
| Integration | Language modules supply servers; plain Neovim needs your LSP configuration |
| Services and capabilities | No daemon or language-support provider declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| No completion or LSP attachment | This module supplies the editor; select AstroNvim for the catalog setup |
| Default editor | Set `programs.neovim.defaultEditor = true` when you want to replace the base editor |
| User configuration | Existing Neovim configuration remains user-owned |

## Guarantees

| Guarantee | Covered by |
| -- | -- |
| Enables Neovim and installs the configured NixOS editor package | `check.nix` |
| Leaves the default-editor setting overridable through `programs.neovim.defaultEditor` | `tests.nix` |
