# Modules

LimaNix uses [NixOS](https://nixos.org/) to configure the Linux system in each
VM. Select modules to add tools, services and settings. Each module owns its
configuration, integrations, tests and documentation; all selected modules
contribute to the same system.

## Start here

1. [Choose a composition](catalog.md#choose-a-composition) for your project.

1. Open each module's page for its versions, settings, commands and corner
   cases.

1. Add the selectors to your VM configuration. For a terminal and Go toolchain:

   ```toml
   [nixos]
   modules = ["lmx:console", "lmx:go"]
   ```

1. [Apply the configuration](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change),
   then follow the module page's first commands inside the VM.

The client guide [Modules](https://limanix.dev/categories/client/modules.html)
explains listing, selecting and importing modules. An empty selection keeps the
VM's platform; optional applications come from your chosen modules.

## Find the right guide

| Goal                                                        | Page                                    |
| ----------------------------------------------------------- | --------------------------------------- |
| Select ready-made tools and their version lines             | [Catalog](catalog.md)                   |
| Understand the platform, module boundaries and composition  | [Concepts](concepts.md)                 |
| Add project settings or create a module                     | [Write a module](writing-modules.md)    |
| Maintain a catalog module's public interface and guarantees | [Catalog contract](catalog-contract.md) |
| Run checks and understand timings and cache results         | [Automation](automation.md)             |
| Diagnose evaluation, command or activation failures         | [Troubleshooting](troubleshooting.md)   |

```{toctree}
:hidden:

catalog
concepts
writing-modules
catalog-contract
automation
troubleshooting
```
