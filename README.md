# LimaNix modules

[![License: Apache-2.0](https://img.shields.io/github/license/limanix/modules?label=license)](LICENSE)

<p align="center">
  <img src=".github/assets/readme-header.png"
       alt="LimaNix modules"
       width="100%">
</p>

The NixOS module catalog for [LimaNix](https://github.com/limanix/client), which
runs Linux development environments on macOS. Select and combine language
toolchains, services and terminal tools in `limanix.toml` without writing Nix.

This repository provides the guest software, application configuration and
integrations. The LimaNix client manages VM lifecycle and bundles one catalog
release in each binary.

[Documentation](https://limanix.dev/categories/nixos/index.html) |
[Catalog](guides/catalog.md) |
[Releases](https://github.com/limanix/modules/releases)

## Get started

Install the client using
[Getting started](https://limanix.dev/categories/client/getting-started.html).
Run `limanix modules list` on your Mac to see the selectors bundled with your
client. Select tools in the `[nixos]` table of your `limanix.toml`:

```toml
[nixos]
modules = ["lmx:go", "lmx:docker", "lmx:python-3.12"]
```

Follow the
[client module guide](https://limanix.dev/categories/client/modules.html) to
create a VM, apply changes or import custom modules.

## Documentation

| Guide                                          | Contents                                                                   |
| ---------------------------------------------- | -------------------------------------------------------------------------- |
| [Catalog](guides/catalog.md)                   | Available modules, version selectors and links to each module's reference. |
| [Concepts](guides/concepts.md)                 | NixOS configuration, composition and package pins.                         |
| [Write a module](guides/writing-modules.md)    | Custom modules and adding them to the catalog.                             |
| [Catalog contract](guides/catalog-contract.md) | Responsibilities, compatibility and required checks.                       |
| [Troubleshooting](guides/troubleshooting.md)   | Configuration errors, builds and catalog checks.                           |

The guides and module references are published at
[limanix.dev](https://limanix.dev/categories/nixos/index.html).

## Contributing

Follow the
[contribution guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md)
and [catalog contract](guides/catalog-contract.md) when adding or changing a
module. See [Check the result](guides/writing-modules.md#check-the-result) and
[Taskfile.yml](Taskfile.yml) for local checks. Use
[Issues](https://github.com/limanix/modules/issues) for questions, bug reports
and feature requests.

Licensed under [Apache 2.0](LICENSE).
