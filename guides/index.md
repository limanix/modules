# NixOS modules

Modules add tools and services to a Limanix Linux VM.
Choose ready-made modules in `limanix.toml`, or write a small Nix file for a tool the catalog does not include.

```toml
[nixos]
modules = ["lmx:git", "lmx:python"]
```

This selection adds Git and Python inside the VM.
The [getting started guide](using-modules.md) shows how to create the VM and run them.

## Start here

| You want to… | Read |
| --- | --- |
| Install a language toolchain or Docker | [Use catalog modules](using-modules.md) |
| Find a tool's versions and commands | [Module catalog](catalog.md) |
| Understand a Nix module | [Module concepts](concepts.md) |
| Install a package or enable a service of your own | [Write your first module](writing-modules.md) |
| Give a shared module configurable settings | [Make a module configurable](reusable-modules.md) |
| Build or run dependencies that need system libraries | [Use native dependencies](native-dependencies.md) |
| Import, replace, or remove a local module | [Choose and manage modules](https://limanix.dev/categories/client/modules.html) |
| Diagnose an error | [Troubleshooting](troubleshooting.md) |
| Add a module to this repository | [Contributing to the catalog](contributing.md) |

These guides cover catalog tools and Nix code.
The client guide [Choose and manage modules](https://limanix.dev/categories/client/modules.html) covers CLI commands, selectors, and the local registry.

```{note}
These pages describe the catalog in this repository revision.
Run `limanix modules list` on your Mac to see what your installed client includes.
```

```{toctree}
:hidden:
:maxdepth: 1

using-modules
catalog
concepts
writing-modules
reusable-modules
native-dependencies
troubleshooting
contributing
```
