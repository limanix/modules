[![Release](https://img.shields.io/github/v/release/limanix/modules)](https://github.com/limanix/modules/releases)
[![License: Apache-2.0](https://img.shields.io/github/license/limanix/modules?label=license)](LICENSE)

<p align="center">
  <img src=".github/assets/readme-header.png"
       alt="LimaNix modules"
       width="100%">
</p>

<p align="center">
  <a href="https://docs.limanix.dev"><b>Docs</b></a>
  &nbsp;|&nbsp;
  <a href="https://docs.limanix.dev/modules/"><b>The catalog</b></a>
  &nbsp;|&nbsp;
  <a href="https://docs.limanix.dev/modules/custom"><b>Your own modules</b></a>
  &nbsp;|&nbsp;
  <a href="https://docs.limanix.dev/architecture"><b>How it works</b></a>
  &nbsp;|&nbsp;
  <a href="https://github.com/limanix/modules/releases"><b>Releases</b></a>
</p>

<hr>

The NixOS catalog of [LimaNix](https://limanix.dev), which runs NixOS
development VMs on a Mac. It holds the shells, toolchains and services that
`limanix.toml` chooses without any Nix, and the base disk that every new VM
boots from. Each [`limanix`](https://github.com/limanix/client) release bundles
one catalog release.

```text
┌─────────────┐  release vN   ┌────────────┐  limanix.toml   ┌─────────────────┐
│   modules   │ ────────────> │  limanix   │ ──────────────> │        VM       │
│  this repo  │  bundled in   │ on the Mac │ create, update  │ NixOS + catalog │
└─────────────┘               └────────────┘                 └─────────────────┘
```

| Kind | Chosen in `limanix.toml` | Modules |
| -- | -- | -- |
| `shell` | `[shell]` | zsh, tmux, astronvim, neovim, yazi, lazygit, cli-tools |
| `toolchains` | `[toolchains]` | go, python, nodejs, rust, java, maven, gradle |
| `modules` | `[nixos] modules`, as `lmx:<name>` | docker, gcloud, postgres, posting, harlequin, claude, quarkus |

Every module follows the [catalog contract](catalog/README.md), which the client
relies on; its own README explains how to select and use it.

## Repository layout

```text
modules/
├── catalog/        the catalog: _shared/, shell/, toolchains/, modules/ and graph.json
├── checks/         the harness in Nix: discovery, contract validation and test aggregation
├── tools/          the harness in Python: the check runner, updates, the disk build, releases and the graph
├── interface.nix   the options every VM gets: account identity, sessions and help cards
├── platform.nix    the guest platform: disk layout, boot loader and Lima integration
├── image.nix       the base disk, built from platform.nix
└── flake.nix       the Nixpkgs and nixos-lima pins, and the disk outputs
```

A client bundles `LICENSE`, `flake.lock`, `interface.nix`, `platform.nix` and
`catalog/`; everything else stays here. Nix evaluates and builds: every check is
an evaluation or a derivation that `checks/` assembles from the `test.nix`
exports of the modules. `tools/harness`, a Python program with no dependencies
beyond the standard library, only orchestrates: it selects what to check, calls
Nix and reports.

## Base disk

Each release carries the disk a new VM boots from: NixOS for `aarch64` and
`x86_64`, built from this catalog's Nixpkgs with [`platform.nix`](platform.nix)
and [`image.nix`](image.nix). The labels, file systems and boot loader of a
released disk never change. `task release/build` builds the disk of the
machine's architecture into `dist/`.

## Releases

A tag `v<N>` on `main` releases the catalog with its disks.

| Change | What happens |
| -- | -- |
| Nixpkgs moves within the NixOS release | Every Monday the Check update flow opens a pull request that merges itself once the checks pass |
| nixos-unstable moves | Every Monday the Check update flow opens a separate pull request that merges itself once the checks pass |
| A new NixOS release is published | The Check update flow opens a pull request that waits: boot the image artifact of its checks in Lima, then merge |
| `flake.lock` or `catalog/_shared/unstable.toml` changes on `main` | The Tag flow creates the next `v<N>`, which releases |
| Anything else | Create the next `v<N>` by hand |

## Development

You need [Task](https://taskfile.dev) 3.53.1 or newer and Docker; every task
runs in a container. Nix and Python commands use the same image, pinned by its
multi-architecture digest in `Taskfile.yml`. The harness uses Python's standard
library; ruff, mypy and pytest are development tools in that image.

| Task | Does |
| -- | -- |
| `task ci/nix/fmt`, `task ci/nix/lint` | Checks Nix formatting; lints Nix with statix and deadnix |
| `task ci/markdown/fmt` | Checks Markdown formatting |
| `task ci/python/fmt`, `task ci/python/lint`, `task ci/python/typecheck`, `task ci/python/test` | Checks the harness with ruff, mypy and pytest |
| `task ci/catalog/modules MODE=eval MODULES="go docker"` | Checks the named modules, or all of them; `MODE` is `check`, `eval` or `run` |
| `task ci/catalog/layer SUITE=shared MODE=eval` | Checks the shared layer, or the harness with `SUITE=platform` |
| `task generate/graph` | Writes `catalog/graph.json`, the site's catalog graph, from the `graph.toml` of each module |
| `task harness -- plan --base main` | Prints the checks selected by committed changes from `main` to `HEAD`, including dependent modules |
| `task harness -- update nixpkgs` | Updates a pinned input; accepts `nixpkgs`, `unstable` or `nixos` |
| `task release/build` | Builds the base disk of this machine's architecture into `dist/` |

`task nix/fmt/fix`, `task nix/lint/fix`, `task markdown/fmt/fix`,
`task python/fmt/fix` and `task python/lint/fix` rewrite the files in place.
`task harness -- --help` lists the commands of the harness. The PR planner
includes dependencies from module code and tests; both evaluation and native
execution run on both Linux architectures. Lint runs alongside the selected
checks, and PRs build disks only when disk inputs or their build workflow
change.

## Contributing

Follow the
[contribution guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md).
Use [Issues](https://github.com/limanix/modules/issues) for questions, bug
reports and feature requests. Licensed under [Apache 2.0](LICENSE).
