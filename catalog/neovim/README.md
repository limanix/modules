# Neovim

Enables the Neovim text editor inside the VM.

## Enable

Add `lmx:neovim` to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:neovim"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Version

This module enables the NixOS `programs.neovim` option.
Neovim comes from the VM's base Nixpkgs; the module does not pin a separate release or provide version selectors.

## Use

Inside the VM, open or create a text file in your project directory:

```console
nvim notes.txt
```

To see the installed version, run `nvim --version`.

## Language servers

This module does not configure Neovim's LSP client.
To use a server installed by another module, configure [Neovim LSP](https://neovim.io/doc/user/lsp/) to launch it inside the VM.
See the [Go](../go/README.md) and [Rust](../rust/README.md) modules for the server commands.

## Use Neovim as the default editor

Enabling this module does not make Neovim the default editor.
The guest base sets `EDITOR` to `nano` unless another setting overrides it.

Keep `lmx:neovim` selected and save this as `default.nix` in a new [custom module](../../guides/writing-modules.md) directory:

```nix
{
  programs.neovim.defaultEditor = true;
}
```

Register and select the custom module, then update the VM from your Mac as described in that guide.
This changes the system's default `EDITOR` value to `nvim` for programs that use this variable.
