# Contributing to the catalog

This repository holds the LimaNix catalog, the NixOS modules that
`limanix.toml` chooses, and the base disk every new VM boots from. The
[organization guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md)
covers issues, release labels and the license; this guide covers the work in
this repository.

## Set up

You need [Task](https://taskfile.dev) 3.53.1 or newer and Docker. Every task
runs in the container that CI uses; `task -l` lists them.

## Find the rules for your change

| You want to | Read | Check with |
| -- | -- | -- |
| Add or change a module | [Catalog contract](catalog/README.md) | `task ci/catalog/modules MODULES="<name>"` |
| Use shared helpers, capabilities or theme colors | [Shared helpers](catalog/_shared/README.md) | `task ci/catalog/layer` |
| Give a tool the guest's colors | [Colors and themes](catalog/README.md#colors-and-themes) | The module's checks |
| Add a theme | [Colors and themes](catalog/README.md#colors-and-themes) | `task generate/previews`, then the layer and the modules with colors |
| Add a prompt | [Prompts](catalog/README.md#prompts) | `task ci/catalog/modules MODULES="<name>"`, then `task generate/previews` |
| Change the harness in `tools/` or `checks/` | [Repository layout](README.md#repository-layout) | `task ci/python/test` and the other `ci/python/*` tasks |
| Move a Nixpkgs pin | [Releases](README.md#releases) | `task harness -- update nixpkgs` |

`task harness -- plan --base main` prints the checks CI will select for your
branch, dependent modules included.

## Add a module

1. Create `catalog/<kind>/<name>/` with `module.toml`, `default.nix`, `test.nix`
   and `README.md`, as the [catalog contract](catalog/README.md#add-a-module)
   describes.
2. Give every public entry a help card, and every setting a user may replace
   `lib.mkDefault`.
3. Use other modules only through their public options and the shared
   capabilities.
4. If the tool draws colors, take them from the theme by role.
5. Write `eval` checks for the configuration, `run` checks for behavior that
   runs offline, and list in `builds` each derivation the checks build locally.
6. Write the README for a user: select, versions, use, settings and corner
   cases. It becomes the module's page on docs.limanix.dev.
7. Add a `graph.toml` node and run `task generate/graph` if the module belongs
   on the site's catalog graph.

## Before you open a pull request

| Step | Command |
| -- | -- |
| Check the modules you changed, or the layer for `_shared` | `task ci/catalog/modules MODULES="<names>"`, `task ci/catalog/layer` |
| Check formatting and lint | `task ci/nix/fmt`, `task ci/nix/lint`, `task ci/markdown/fmt` |
| Check the harness after a change in `tools/` | `task ci/python/fmt`, `task ci/python/lint`, `task ci/python/typecheck`, `task ci/python/test` |
| Regenerate generated files | `task generate/graph` after a `graph.toml` change; `task generate/previews` after a theme, color or prompt change |

The `nix/fmt/fix`, `nix/lint/fix`, `markdown/fmt/fix`, `python/fmt/fix` and
`python/lint/fix` tasks rewrite files in place. Update a module's README in the
same pull request as its behavior. Keep one change per pull request, and give it
a release label.

## Releases and the client

A tag `v<N>` on `main` releases the catalog and its disks; the
[README](README.md#releases) lists what creates a tag. Each client build bundles
one catalog release. A change to selectors, metadata, public options,
capabilities or the list of themes reaches users only with a client release that
bundles it; release the catalog first, then open the client pull request that
moves to it.
