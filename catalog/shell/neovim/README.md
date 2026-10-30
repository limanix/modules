# Neovim

Enables the Neovim text editor through the NixOS `programs.neovim` option.

## Select

Choose it as the editor in the `[shell]` table:

```toml
[shell]
editor = "neovim"
```

[Apply the change](https://docs.limanix.dev/vms/update#apply-a-change) after
editing `limanix.toml`. `editor = "astronvim"` also installs Neovim, configured
as [AstroNvim](../astronvim/README.md).

## Versions

Neovim comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Inside the VM, `nvim --version` shows the
installed version.

## Use

Inside the VM, open a file with the `nvim` command:

```console
nvim notes.md
```

The `vi` and `vim` aliases also launch Neovim.

With a theme other than `system` in `[theme]` of `limanix.toml`, Neovim uses the
theme's own colorscheme, the same one as
[AstroNvim](../astronvim/README.md#personal-configuration); a theme without one
draws its palette with catppuccin-nvim. Your `init.lua` or `init.vim` runs after
it and may choose another colorscheme. The `system` theme keeps Neovim's default
colorscheme.

## Make Neovim the default editor

The module leaves `EDITOR` at its NixOS default, `nano`. To make Neovim the
editor for programs that read `EDITOR`, such as `git commit`, add a
[custom module](https://docs.limanix.dev/modules/custom) with this setting:

```nix
{
  programs.neovim.defaultEditor = true;
}
```

## Language servers

The module does not configure Neovim's LSP client. To use `gopls` from the
[Go module](../../toolchains/go/README.md) or `rust-analyzer` from the
[Rust module](../../toolchains/rust/README.md), configure
[Neovim's LSP client](https://neovim.io/doc/user/lsp/) to start the server.
[Editor integration](https://docs.limanix.dev/config/toolchains#language-servers-in-the-editor)
describes the options.

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
