# Limanix modules

[![License: Apache-2.0](https://img.shields.io/github/license/limanix/modules?label=license)](LICENSE)

**Ready-made development tools and services for [Limanix](https://github.com/limanix/client).**

Limanix runs Linux development environments on macOS.
Keep your project and editor on your Mac, and run language toolchains, containers, and builds in a NixOS VM.

This repository is a dependency of the **[Limanix client](https://github.com/limanix/client)**.
The client bundles a tagged release of the catalog, ready to select from your project configuration.
Use the client to create and manage environments; this repository supplies their catalog of tools and services.

[Explore Limanix](https://github.com/limanix/client) · [Documentation](https://limanix.dev) · [Catalog releases](https://github.com/limanix/modules/releases)

## What lives here

| Content | Purpose |
| --- | --- |
| [Modules](catalog/) | Toolchains, services, and utilities, with a README for each module |
| [Nixpkgs pin](flake.lock) | The package collection revision used by the client’s VMs and catalog checks |
| [Guides](guides/index.md) | NixOS basics, module authoring, and native dependencies |
| [Checks](checks/) | Catalog validation and NixOS configuration evaluation |

To add or update a module, see [Catalog development](guides/extending-catalog.md).

Licensed under [Apache 2.0](LICENSE).
