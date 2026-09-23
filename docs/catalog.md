# Module catalog

Use a catalog selector in the `nixos.modules` list:

```toml
[nixos]
modules = ["lmx:git", "lmx:go-1.27"]
```

These tables describe the repository source used for this documentation.
Your installed client can contain a different catalog. 
Check its selectors before editing a configuration:

```console
limanix modules list
```

For the steps to apply a selection, see [Using modules](using-modules.md).

## At a glance

| Module   | Default selector        | Available version selectors    | Provides                                |
|----------|-------------------------|--------------------------------|-----------------------------------------|
| Git      | `lmx:git`               | None                           | Git                                     |
| Neovim   | `lmx:neovim`            | None                           | Neovim                                  |
| Docker   | `lmx:docker` → `29`     | `28`, `29`                     | Docker Engine, CLI and Compose          |
| Go       | `lmx:go` → `1.27`       | `1.24`, `1.25`, `1.26`, `1.27` | Go, gopls and Delve                     |
| Minikube | `lmx:minikube` → `1.38` | `1.36`, `1.37`, `1.38`         | Minikube                                |
| Node.js  | `lmx:nodejs` → `26`     | `23`, `24`, `25`, `26`         | Node.js, npm and npx                    |
| Python   | `lmx:python` → `3.14`   | `3.12`, `3.13`, `3.14`         | Python and virtualenv                   |
| Rust     | `lmx:rust` → `1.98`     | `1.95`, `1.96`, `1.97`, `1.98` | Rust toolchain, GCC, pkg-config and GDB |

Append a version selector to the module name: `lmx:python-3.12`.
Omit it to use that catalog's default: `lmx:python`.

```{important}
A selector chooses a version line, not an exact patch forever.
For example, `lmx:go-1.27` selects Go 1.27.1 in this catalog snapshot.
A later catalog can update that line to another patch. 
The catalog bundled with the client determines the actual package sources.
```

## Several versions in one VM

Go, Minikube, Node.js, Python and Rust provide versioned commands. 
Select the versions you need together:

```toml
[nixos]
modules = ["lmx:nodejs-24", "lmx:nodejs-26"]
```

| Command            | Selection in this example                       |
|--------------------|-------------------------------------------------|
| `node`             | Highest selected version: Node.js 26            |
| `node-24`          | Node.js 24                                      |
| `node-26`          | Node.js 26                                      |
| `npm-24`, `npx-24` | npm/npx with the Node.js 24 toolchain on `PATH` |

The same priority rule applies to the other versioned toolchain modules:
the highest selected release takes priority for shared command names.
**Docker is different: select one Docker version per VM.**

## Git and Neovim

```toml
[nixos]
modules = ["lmx:git", "lmx:neovim"]
```

These modules enable the NixOS `programs.git` and `programs.neovim` options.
Their package versions come from the VM's base Nixpkgs. 
They have no separate version selector in this catalog.

## Docker

Enables the system Docker service and adds the VM user to the `docker` group.
Use `docker` and `docker compose` inside the guest.

| Selector                      | Docker Engine / CLI | Catalog warning                  |
|-------------------------------|---------------------|----------------------------------|
| `lmx:docker`, `lmx:docker-29` | 29.8.0              | None                             |
| `lmx:docker-28`               | 28.5.2              | End of upstream security support |

```{warning}
Membership in the `docker` group grants root-equivalent access inside the VM.
```

Changing the selected version uses the same Docker container and volume storage.
It does not create a separate Docker environment.

Source: [Docker module](https://github.com/limanix/modules/blob/main/modules/docker/module.nix) and [release pins](https://github.com/limanix/modules/blob/main/modules/docker/releases.nix).

## Go

Installs the compiler, gopls language server and Delve debugger.

| Selector                | Go      | Catalog warning                  |
|-------------------------|---------|----------------------------------|
| `lmx:go`, `lmx:go-1.27` | 1.27.1  | None                             |
| `lmx:go-1.26`           | 1.26.7  | None                             |
| `lmx:go-1.25`           | 1.25.13 | End of upstream security support |
| `lmx:go-1.24`           | 1.24.13 | End of upstream security support |

Use `go-1.26` or `go-1.27` to choose an installed compiler explicitly.
The `go`, `gopls` and `dlv` commands follow the highest selected Go module's package priority.

Go can download another toolchain according to a project's requirements.
To use only the selected local toolchain, set `GOTOOLCHAIN` in the VM's `[env]` table. 
If you started with `env = {}`, remove that top-level line before adding the table below:

```toml
[env]
GOTOOLCHAIN = "local"
```

With this setting, a project that requires a newer Go version fails instead of downloading it. 
See [Go toolchain selection](https://go.dev/doc/toolchain).

Source: [Go module](https://github.com/limanix/modules/blob/main/modules/go/module.nix) and [release pins](https://github.com/limanix/modules/blob/main/modules/go/releases.nix).

## Minikube

| Selector                            | Minikube |
|-------------------------------------|----------|
| `lmx:minikube`, `lmx:minikube-1.38` | 1.38.1   |
| `lmx:minikube-1.37`                 | 1.37.0   |
| `lmx:minikube-1.36`                 | 1.36.0   |

The module installs Minikube. 
It does not start a cluster or enable Docker.
For the Docker driver, select both modules:

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube-1.36", "lmx:minikube-1.38"]
```

Run each version with a separate cluster profile inside the VM:

```console
minikube-1.36 start --driver=docker --profile=mk136
minikube-1.38 start --driver=docker --profile=mk138
```

Source: [Minikube module](https://github.com/limanix/modules/blob/main/modules/minikube/module.nix)
and [release pins](https://github.com/limanix/modules/blob/main/modules/minikube/releases.nix).

## Node.js

| Selector                      | Node.js | Catalog warning                  |
|-------------------------------|---------|----------------------------------|
| `lmx:nodejs`, `lmx:nodejs-26` | 26.9.0  | None                             |
| `lmx:nodejs-25`               | 25.9.0  | End of upstream security support |
| `lmx:nodejs-24`               | 24.20.0 | None                             |
| `lmx:nodejs-23`               | 23.11.0 | End of upstream security support |

Each selected version includes Node.js, npm and npx. 
Versioned commands are `node-24`, `npm-24`, `npx-24`, and their equivalents for other selectors.
The npm/npx wrappers put the matching Node.js toolchain first on `PATH`, including when they run project scripts.

Source: [Node.js module](https://github.com/limanix/modules/blob/main/modules/nodejs/module.nix) and [release pins](https://github.com/limanix/modules/blob/main/modules/nodejs/releases.nix).

## Python

| Selector                        | Python  |
|---------------------------------|---------|
| `lmx:python`, `lmx:python-3.14` | 3.14.7  |
| `lmx:python-3.13`               | 3.13.15 |
| `lmx:python-3.12`               | 3.12.14 |

Includes Python with `venv` and the `virtualenv` tool. 
Use a versioned interpreter to create a project environment inside the VM:

```console
python-3.12 -m venv .venv
source .venv/bin/activate
```

The corresponding virtualenv command is:

```console
virtualenv --python python-3.12 .venv
```

Source: [Python module](https://github.com/limanix/modules/blob/main/modules/python/module.nix) and [release pins](https://github.com/limanix/modules/blob/main/modules/python/releases.nix).

## Rust

Installs rustc, Cargo, rustfmt, Clippy and rust-analyzer. 
GCC, pkg-config and GDB are also included from the VM's base Nixpkgs.

| Selector                    | Rust   | Catalog warning                  |
|-----------------------------|--------|----------------------------------|
| `lmx:rust`, `lmx:rust-1.98` | 1.98.1 | None                             |
| `lmx:rust-1.97`             | 1.97.1 | End of upstream security support |
| `lmx:rust-1.96`             | 1.96.1 | End of upstream security support |
| `lmx:rust-1.95`             | 1.95.0 | End of upstream security support |

Use the versioned Cargo wrapper for the matching toolchain:

```console
cargo-1.95 build
cargo-1.95 fmt
cargo-1.95 clippy
```

Other versioned commands are `rustc-1.95`, `rustdoc-1.95`, `rustfmt-1.95` and `rust-analyzer-1.95`. 
Equivalent commands exist for every selected Rust version.

Source: [Rust module](https://github.com/limanix/modules/blob/main/modules/rust/module.nix) and [release pins](https://github.com/limanix/modules/blob/main/modules/rust/releases.nix).

## Where the package versions come from

Each versioned module records its package choices in `releases.nix`:

1. A Nixpkgs Git revision identifies the package source snapshot.
2. A content hash checks the downloaded source tree.
3. A package attribute chooses the tool from that snapshot.
4. An assertion checks the main tool's expected version during evaluation.

Related tools come from the chosen snapshot unless the module supplies an explicit override. 
For example, Node.js 26 includes a separately pinned npm package. 
A selector does not mean "download the newest upstream release".

The warning columns above reflect the catalog's `endOfLife` flags. 
They describe the behavior of this source snapshot, rather than a live upstream support lookup.
For adding or updating these entries, see [Contributing to the catalog](contributing.md).
