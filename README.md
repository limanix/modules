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
- Each directory in [`catalog/`](catalog/) except `_shared` is one module.
  Its README lists the selectors, exact versions, commands, and guarantees.
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
| Catalog ownership, capabilities, compatibility, and required checks | [Catalog contract](guides/catalog-contract.md) |
| Evaluation errors, build failures, services, and catalog checks  | [Troubleshooting](guides/troubleshooting.md) |

The guides and every module README are also published on the [documentation site](https://limanix.dev/categories/nixos/index.html).

## Repository layout

| Path                      | Contents                                                                                       |
|---------------------------|------------------------------------------------------------------------------------------------|
| `catalog/NAME/`           | One module: `default.nix`, `module.toml`, `check.nix`, `README.md`, and optional version lines |
| `checks/`                 | Catalog validation, NixOS evaluation, and build/runtime checks run by `ci/test`                 |
| `flake.nix`, `flake.lock` | The NixOS release and the base Nixpkgs revision                                                |
| `guides/`                 | The guides listed above                                                                        |
| `scripts/`                | Documentation preparation, the check runner, and the Nixpkgs update summary                    |

## Develop

Install [Task](https://taskfile.dev) 3.53.1 or newer and Docker with a running engine.
Nix runs in a container; you do not need a local Nix installation.

```console
task --yes ci/nixos-fmt ci/nixos-lint ci/test
```

See [Taskfile.yml](Taskfile.yml) for the full task list.

`ci/test` evaluates both guest architectures and builds and runs every applicable module smoke check for the container's native Linux architecture.
Use `ci/eval ARCH=arm64` or `ci/eval ARCH=amd64` to evaluate one architecture.
`ci/smoke ARCH=arm64` or `ci/smoke ARCH=amd64` requires a matching native Linux container; it rejects a different architecture.
CI runs the complete checks on native ARM64 and AMD64 runners.
`ci/test` keeps evaluation and smoke in one container and reuses its Nix store.
The runner evaluates checks in bounded parallel batches and builds each distinct smoke derivation once.
CI restores source and binary caches separately for each architecture and saves completed builds even when a later check fails.
Run `PR flow` manually on `main` to prepare a base cache accessible to other branches; a cache saved by a pull request is scoped to that pull request.
The first cache preparation can compile pinned dependencies that are absent from the public Nix cache.
The binary cache includes the runtime dependencies of locally built results; Nix still checks the derivation paths against the current configuration.
Set `NIX_CHECK_JOBS` and `NIX_CHECK_BATCH_SIZE` through `CONTAINER_ENVS` to tune evaluator concurrency and memory use.
These checks do not boot the complete Lima VM.
Run a changed module's documented commands in a VM as well.

To contribute a module, follow [Add to the catalog](guides/writing-modules.md#add-to-the-catalog) and the [contribution guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md).

## Release

A catalog release is an integer tag, such as `v2`, on a commit in `main`.
The release workflow publishes a GitHub release with the documentation archive and triggers the client rebuilds described in [Use a module](#use-a-module).
