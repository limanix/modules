# LimaNix modules

[![License: Apache-2.0](https://img.shields.io/github/license/mr-chelyshkin/images?label=license)](LICENSE)

<p align="center">
  <img src=".github/assets/readme-header.png"
       alt="github.com/mr-chelyshkin/images"
       width="800">
</p>

**Ready-made development tools and services for [LimaNix](https://github.com/limanix/client).**

LimaNix runs Linux development environments on macOS.
Keep your project and editor on your Mac, and run language toolchains, containers, and builds in a NixOS VM.

This repository is a dependency of the **[LimaNix client](https://github.com/limanix/client)**.
The client bundles a tagged release of the catalog, ready to select from your project configuration.
Use the client to create and manage environments; this repository supplies their catalog of tools and services.

[Explore LimaNix](https://github.com/limanix/client) · [Documentation](https://limanix.dev) · [Catalog releases](https://github.com/limanix/modules/releases)

## What lives here

| Content                   | Purpose                                                                     |
|---------------------------|-----------------------------------------------------------------------------|
| [Modules](catalog/)       | Toolchains, services, and utilities, with a README for each module          |
| [Nixpkgs pin](flake.lock) | The package collection revision used by the client’s VMs and catalog checks |
| [Guides](guides/index.md) | NixOS concepts, module authoring, and native dependencies                   |
| [Checks](checks/)         | Catalog validation and NixOS configuration evaluation                       |

Start with [Write a module](guides/writing-modules.md), then [add it to the catalog](guides/writing-modules.md#add-to-the-catalog) if you want to contribute it.

Licensed under [Apache 2.0](LICENSE).
