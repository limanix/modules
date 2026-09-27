---
myst:
  heading_anchors: 2
---

# Catalog

The catalog is the set of modules maintained in this repository.
Each Limanix client release bundles one catalog release.
You can add its tools to a VM by name, without writing Nix.

| Module | Selector | Provides |
| --- | --- | --- |
| [Docker](../catalog/docker/README.md) | `lmx:docker` | Docker Engine, CLI, and Compose |
| [Git](../catalog/git/README.md) | `lmx:git` | Git |
| [Go](../catalog/go/README.md) | `lmx:go` | Go, gopls, Delve, and GCC |
| [Minikube](../catalog/minikube/README.md) | `lmx:minikube` | Minikube for local Kubernetes clusters |
| [Neovim](../catalog/neovim/README.md) | `lmx:neovim` | Neovim |
| [Node.js](../catalog/nodejs/README.md) | `lmx:nodejs` | Node.js, npm, and npx |
| [Python](../catalog/python/README.md) | `lmx:python` | Python, venv, and virtualenv |
| [Rust](../catalog/rust/README.md) | `lmx:rust` | Rust toolchain, rust-analyzer, GCC, pkg-config, and GDB |

The Docker module gives the VM user root-equivalent access through the `docker` group.

Each module page lists its selectors, exact versions, and commands.
This page describes the catalog in this revision of the repository, and your client may bundle an older one.
To see the selectors that your client provides, [list the available modules](https://limanix.dev/categories/client/modules.html#list-available-modules).

## Versions

Docker, Go, Minikube, Node.js, Python, and Rust offer several version lines.
Select a line by adding its version to the selector:

| Selector | Installs |
| --- | --- |
| `lmx:python` | The module's default line, named on its page |
| `lmx:python-3.12` | The Python 3.12 line |

Git and Neovim have no version lines; they come from the [base Nixpkgs revision](concepts.md#nixos-version-and-package-pins).

Docker and Node.js lines fix the major version, allowing minor and patch updates in later catalog releases.
The other versioned modules fix major and minor, allowing only patch updates within a line.
A catalog release can also choose another default line.

Lines past their upstream end of life stay selectable, and each module page marks them.
Selecting one prints a warning when the VM is built, and the build continues:

```text
evaluation warning: Go 1.24.13 no longer receives upstream security updates.
```

## Several versions in one VM

Go, Minikube, Node.js, Python, and Rust can install several lines side by side:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

Each line adds commands with a version suffix, such as `python-3.12` and `python-3.14`.
Commands without a suffix, such as `python`, run the newest selected line.
Each module page lists its versioned commands.

Docker runs one system service.
Select only one Docker line per VM; see the [Docker page](../catalog/docker/README.md).

## Editor integration

The Go and Rust modules install language servers: `gopls` and `rust-analyzer`.
The catalog installs them but does not configure any editor.

| Where the editor runs | What connects it to the language server |
| --- | --- |
| Inside the VM, such as Neovim | The editor's LSP client, configured to start the server |
| On your Mac | The editor's remote development support, connected to the VM with the project open at its path in the VM |

Limanix does not set up remote editor connections; sharing a project directory with the VM shares only its files.

For software that the catalog does not provide, [write a module](writing-modules.md).
