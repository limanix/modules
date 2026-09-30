# LimaNix modules

[![License: Apache-2.0](https://img.shields.io/github/license/limanix/modules?label=license)](LICENSE)

<p align="center">
  <img src=".github/assets/readme-header.png"
       alt="LimaNix modules"
       width="100%">
</p>

The NixOS module catalog for [LimaNix](https://github.com/limanix/client).
Add language toolchains, Docker, Kubernetes tools, and editors to a VM by name without writing Nix.

[Catalog](guides/catalog.md) |
[Write a module](guides/writing-modules.md) |
[Releases](https://github.com/limanix/modules/releases) |
[Documentation](https://limanix.dev/categories/nixos/index.html)

## Use a module

List selectors in the `[nixos]` table of your `limanix.toml`:

```toml
[nixos]
modules = ["lmx:go", "lmx:docker", "lmx:python-3.12"]
```

Apply the selection with `limanix update --config limanix.toml`, or with `limanix create --config limanix.toml` for a new VM.

- `lmx:NAME` installs the module's default version line, and `lmx:NAME-VERSION` installs a specific one.
- Each directory in [`catalog/`](catalog/) is one module. Its README lists the selectors, exact versions, and commands.
- `limanix modules list` shows the selectors that your client provides.

The client binary embeds one catalog release and does not download modules.
After a new catalog release, recent client versions are rebuilt with it and published as new builds, such as `v0.0.1+1`.
Install the latest build of your client version to get the updated catalog.
The [release process](https://limanix.dev/releases/index.html) describes the details.

For tools the catalog does not cover, [write your own module](guides/writing-modules.md) and import it with `limanix modules add`.

## Find the right guide

| Topic                                                            | Guide                                        |
|------------------------------------------------------------------|----------------------------------------------|
| Available modules, version lines, and several versions in one VM | [Catalog](guides/catalog.md)                 |
| NixOS modules, how settings combine, package pins, and trust     | [Concepts](guides/concepts.md)               |
| Writing, combining, and contributing a module                    | [Write a module](guides/writing-modules.md)  |
| Evaluation errors, build failures, services, and catalog checks  | [Troubleshooting](guides/troubleshooting.md) |

The guides and every module README are also published on the [documentation site](https://limanix.dev/categories/nixos/index.html).

## Repository layout

| Path                      | Contents                                                                                       |
|---------------------------|------------------------------------------------------------------------------------------------|
| `catalog/NAME/`           | One module: `default.nix`, `module.toml`, `check.nix`, `README.md`, and optional version lines |
| `checks/`                 | Catalog validation and NixOS evaluation run by `ci/test`                                       |
| `flake.nix`, `flake.lock` | The NixOS release and the base Nixpkgs revision                                                |
| `guides/`                 | The guides listed above                                                                        |
| `scripts/`                | Documentation preparation and the Nixpkgs update summary                                       |

## Develop

Install [Task](https://taskfile.dev) 3.53.1 or newer and Docker with a running engine.
Nix runs in a container; you do not need a local Nix installation.

```console
task --yes ci/nixos-fmt ci/nixos-lint ci/test
```

See [Taskfile.yml](Taskfile.yml) for the full task list.

Add `ARCH=arm64` or `ARCH=amd64` to `ci/test` to evaluate one architecture.
`ci/test` validates catalog metadata and evaluates configurations. It does not build packages or boot a VM. Run a changed module's documented commands in a VM as well.

To contribute a module, follow [Add to the catalog](guides/writing-modules.md#add-to-the-catalog) and the [contribution guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md).

## Release

A catalog release is an integer tag, such as `v2`, on a commit in `main`.
The release workflow publishes a GitHub release with the documentation archive and triggers the client rebuilds described in [Use a module](#use-a-module).
