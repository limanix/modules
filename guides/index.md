# Modules

LimaNix configures every VM with [NixOS](https://nixos.org/).
A module is a piece of that configuration: it adds packages, runs services, or changes system settings inside the VM.
LimaNix ships a catalog of ready-made modules, and you can write your own for anything the catalog does not cover.

| Page                                  | Read it to                                                                                  |
|---------------------------------------|---------------------------------------------------------------------------------------------|
| [Catalog](catalog.md)                 | Choose ready-made toolchains and services, and their versions                               |
| [Concepts](concepts.md)               | Understand NixOS modules, how their settings combine, and where their packages come from    |
| [Write a module](writing-modules.md)  | Write and extend a module, handle native dependencies, and optionally add it to the catalog |
| [Troubleshooting](troubleshooting.md) | Diagnose module errors, build failures, programs and services, and catalog checks           |

The client guide [Modules](https://limanix.dev/categories/client/modules.html) covers the commands that list, import, and apply modules.

```{toctree}
:hidden:

catalog
concepts
writing-modules
troubleshooting
```
