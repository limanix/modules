# Modules

Limanix configures every VM with [NixOS](https://nixos.org/).
A module is a piece of that configuration: it adds packages, runs services, or changes system settings inside the VM.
Limanix ships a catalog of ready-made modules, and you can write your own for anything the catalog does not cover.

```toml
[nixos]
modules = ["lmx:go", "lmx:docker", "third-party:dev-tools"]
```

This selection adds Go and Docker from the catalog, and a custom module named `dev-tools`.

| Page | Read it to |
| --- | --- |
| [Catalog](catalog.md) | Choose ready-made toolchains and services, and their versions |
| [NixOS basics](nixos-basics.md) | Learn the NixOS terms and file format that modules use |
| [Concepts](concepts.md) | See how Limanix builds a VM from its base system and your selection |
| [Write a module](writing-modules.md) | Add packages, programs, and services that the catalog does not provide |
| [Native dependencies](native-dependencies.md) | Build or run project dependencies that need system libraries |
| [Troubleshooting](troubleshooting.md) | Fix errors in module code and programs that fail inside the VM |
| [Catalog development](extending-catalog.md) | Add or update an entry in the catalog |

The client guide [Choose and manage modules](https://limanix.dev/categories/client/modules.html) covers the commands that list, import, and apply modules.

```{toctree}
:hidden:

catalog
nixos-basics
concepts
writing-modules
native-dependencies
troubleshooting
extending-catalog
```
