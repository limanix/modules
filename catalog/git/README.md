# Git

Enables Git version control inside the VM.

## Enable

Add `lmx:git` to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:git"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Version

This module enables the NixOS `programs.git` option.
Git comes from the VM's base Nixpkgs; the module does not pin a separate release or provide version selectors.

## Use

The module does not set your commit name or email.
Inside the VM, check the configured identity from your project's Git repository:

```console
git config --get user.name
git config --get user.email
```

These commands print the values available from Git configuration, if any.
To set an identity for this repository, replace the example values with your own and run inside the VM:

```console
git config --local user.name "Your Name"
git config --local user.email "you@example.com"
```

These settings are saved in the repository's Git configuration.
To see the installed version, run `git --version`.
