# Module catalog

Choose a module below for its versions, commands, and examples.
Each link opens that module's README.

| Module                                    | Default selector | What it adds                                   |
|-------------------------------------------|------------------|------------------------------------------------|
| [Git](../catalog/git/README.md)           | `lmx:git`        | Git version control                            |
| [Neovim](../catalog/neovim/README.md)     | `lmx:neovim`     | The `nvim` text editor                         |
| [Docker](../catalog/docker/README.md)     | `lmx:docker`     | Docker Engine, CLI, and Compose                |
| [Go](../catalog/go/README.md)             | `lmx:go`         | Go, gopls, Delve, and GCC                      |
| [Minikube](../catalog/minikube/README.md) | `lmx:minikube`   | Minikube for running local Kubernetes clusters |
| [Node.js](../catalog/nodejs/README.md)    | `lmx:nodejs`     | Node.js, npm, and npx                          |
| [Python](../catalog/python/README.md)     | `lmx:python`     | Python and virtualenv                          |
| [Rust](../catalog/rust/README.md)         | `lmx:rust`       | Rust toolchain, rust-analyzer, GCC, pkg-config, and GDB |

```{warning}
The Docker module adds the VM user to the `docker` group, which grants root-equivalent access inside the VM.
```

## Check your installed catalog

Run on your **Mac**:

```console
limanix modules list
```

See [List available modules](https://limanix.dev/categories/client/modules.html#list-available-modules) for the command's output and JSON diagnostics.

```{note}
Your client can contain an older catalog than this documentation.
Use a selector that appears in its module list.
```

To get a newer catalog, install a client release that includes it, then update the VMs that need the changes.
Installing a client alone does not change existing VMs.
See {ref}`How catalog changes reach users <catalog-releases>` for the release process.

## Choose a version

A *selector* is the identifier placed in `nixos.modules`.

| Selector | Meaning |
| --- | --- |
| `lmx:python` | The default Python version in your catalog |
| `lmx:python-3.12` | The Python 3.12 line in that catalog |
| `lmx:git` | Git from the VM's base Nixpkgs package collection |

The versioned modules pin their package sources.
A selector such as `lmx:python-3.12` chooses a version line; the module's README gives the exact package version for this revision.
A later catalog release can change a patch version or the default version.

Git and Neovim use the VM's base Nixpkgs and have no separate version selectors.

```{note}
Selecting a version marked end of life (EOL) in the catalog produces a warning during VM creation or update.
This warning alone does not mean the operation failed.
The module's README identifies the versions marked EOL in that catalog revision.
```

## Use several versions

Go, Minikube, Node.js, Python, and Rust provide commands with version suffixes.
For example:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

In this example, `python-3.12` and `python-3.14` select a specific installed interpreter.
Outside an activated virtual environment, the ordinary `python` command uses the highest selected version.
Each README lists the versioned commands its module provides.

````{warning}
Select only one Docker version per VM.
Selecting two different Docker versions makes creation or update fail:

```text
The option `virtualisation.docker.package' is defined multiple times while it's expected to be unique.
```

The Docker module configures one system service and its shared container and volume storage.
````

Follow [Use catalog modules](using-modules.md) to apply your selection.
For tools outside this list, [write your own module](writing-modules.md).
