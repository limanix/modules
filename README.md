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
| `toolchains` | `[toolchains]` | go, python, nodejs, rust |
| `modules` | `[nixos] modules`, as `lmx:<name>` | docker, gcloud, postgres, posting, harlequin, claude |

Every module follows the [catalog contract](catalog/README.md), which the client
relies on; its own README lists what it guarantees and the test that checks each
promise.

## Base disk

Each release carries the disk a new VM boots from: NixOS for `aarch64` and
`x86_64`, built from this catalog's Nixpkgs with [`platform.nix`](platform.nix)
and [`image.nix`](image.nix). The labels, file systems and boot loader of a
released disk never change. `task --yes release/build` builds the disk of the
machine's architecture into `dist/`.

## Releases

A tag `v<N>` on `main` releases the catalog with its disks.

| Change | What happens |
| -- | -- |
| Nixpkgs moves within the NixOS release | Every Monday the Update flow opens a pull request that merges itself once the checks pass |
| nixos-unstable moves | Every Monday the Update flow opens a separate pull request that merges itself once the checks pass |
| A new NixOS release is published | The Update flow opens a pull request that waits: boot the image artifact of its checks in Lima, then merge |
| `flake.lock` or `catalog/_shared/unstable.toml` changes on `main` | The Tag flow creates the next `v<N>`, which releases |
| Anything else | Create the next `v<N>` by hand |

## Development

You need [Task](https://taskfile.dev) 3.53.1 or newer and Docker; every task
runs in a container.

| Task | Does |
| -- | -- |
| `task ci/lint` | Checks Nix and Markdown formatting |
| `task ci/test/modules MODE=eval MODULES="go docker"` | Tests the named modules, or all of them; `MODE` is `check`, `eval`, `run` or `vm` |
| `task ci/test/layer SUITE=shared MODE=eval` | Tests the shared layer, or the platform with `SUITE=platform` |

`MODE=vm` boots VMs and needs Linux with `/dev/kvm`.

## Contributing

Follow the
[contribution guide](https://github.com/limanix/.github/blob/main/CONTRIBUTING.md).
Use [Issues](https://github.com/limanix/modules/issues) for questions, bug
reports and feature requests. Licensed under [Apache 2.0](LICENSE).
