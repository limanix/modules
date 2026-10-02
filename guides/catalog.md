# Catalog

The catalog is the set of modules maintained in this repository.
Each LimaNix client release bundles one catalog release.
You can add its tools to a VM by name, without writing Nix.

| Module                                    | Selector       | Provides                                                |
|-------------------------------------------|----------------|---------------------------------------------------------|
| [Console](../catalog/console/README.md) | `lmx:console` | Zsh, tmux, AstroNvim, CLI tools and terminal applications |
| [Cozy](../catalog/cozy/README.md) | `lmx:cozy` | Project workbench, Console, common languages and LSP, Docker, Minikube, cloud, HTTP and SQL clients |
| [Zsh](../catalog/zsh/README.md) | `lmx:zsh` | Configured shell, prompt, history, completion and direnv |
| [tmux](../catalog/tmux/README.md) | `lmx:tmux` | Sessions, panes, clipboard and layout restoration |
| [AstroNvim](../catalog/astronvim/README.md) | `lmx:astronvim` | Configured Neovim with language-server integration |
| [CLI tools](../catalog/cli-tools/README.md) | `lmx:cli-tools` | Search, previews, Git diffs, data and system tools |
| [Lazygit](../catalog/lazygit/README.md) | `lmx:lazygit` | Git terminal interface |
| [GitHub CLI](../catalog/gh/README.md) | `lmx:gh` | GitHub repositories, pull requests and workflow runs |
| [Yazi](../catalog/yazi/README.md) | `lmx:yazi` | Terminal file manager |
| [Posting](../catalog/posting/README.md) | `lmx:posting` | Saved HTTP requests in the terminal |
| [Harlequin](../catalog/harlequin/README.md) | `lmx:harlequin` | SQL terminal interface with the Postgres adapter |
| [Cloud tools](../catalog/cloud-tools/README.md) | `lmx:cloud-tools` | AWS CLI v2 and Google Cloud CLI |
| [Lazydocker](../catalog/lazydocker/README.md) | `lmx:lazydocker` | Docker terminal interface; also included by Docker |
| [Docker](../catalog/docker/README.md)     | `lmx:docker`   | Docker Engine, CLI, and Compose                         |
| [Git](../catalog/git/README.md)           | `lmx:git`      | Git                                                     |
| [Go](../catalog/go/README.md)             | `lmx:go`       | Go, gopls, Delve, and GCC                               |
| [Helm](../catalog/helm/README.md)         | `lmx:helm`     | Helm package manager for Kubernetes                     |
| [K9s](../catalog/k9s/README.md)           | `lmx:k9s`      | Terminal interface for Kubernetes                       |
| [Minikube](../catalog/minikube/README.md) | `lmx:minikube` | Minikube for local Kubernetes clusters                  |
| [Neovim](../catalog/neovim/README.md)     | `lmx:neovim`   | Neovim                                                  |
| [Node.js](../catalog/nodejs/README.md)    | `lmx:nodejs`   | Node.js, npm, npx and JavaScript/TypeScript LSP |
| [PostgreSQL](../catalog/postgres/README.md) | `lmx:postgres` | PostgreSQL server and tools for manual use              |
| [Python](../catalog/python/README.md)     | `lmx:python`   | Python, venv, virtualenv and Pyright LSP |
| [Rust](../catalog/rust/README.md)         | `lmx:rust`     | Rust toolchain, rust-analyzer, GCC, pkg-config, and GDB |
| [Terraform](../catalog/terraform/README.md) | `lmx:terraform` | Terraform CLI for infrastructure as code                |

The Docker module gives the VM user root-equivalent access through the `docker` group.

Each module page lists its selectors, exact versions, and commands.
This page describes the catalog in this revision of the repository, and your client may bundle an older one.
To see the selectors that your client provides, [list the available modules](https://limanix.dev/categories/client/modules.html#list-available-modules).

## Choose a composition

| Project needs | Module selection |
|---|---|
| Minimal guest or your own custom setup | `modules = []` |
| Terminal work with chosen toolchains | `["lmx:console", "lmx:go"]` |
| Container project | `["lmx:console", "lmx:docker"]` |
| Common development workbench | `["lmx:cozy"]` |
| Rust and infrastructure alongside Cozy | `["lmx:cozy", "lmx:rust", "lmx:terraform", "lmx:helm"]` |

Every selection retains the client's platform account, mounts, SSH and public declarations.
Shared declarations do not activate optional applications.
Console and Cozy assemble independent modules through the same entry points available to direct selectors.
Cozy includes Go, Python and Node.js language support; other toolchains remain explicit choices.
Neither installing cloud clients nor selecting Minikube creates remote resources or a cluster.
Follow [Project workspace](https://limanix.dev/categories/client/workspace.html) for a complete configuration and the project-window workflow.

## Versions

Most of the modules offer several version lines.
Select a line by adding its version to the selector:

| Selector          | Installs                                     |
|-------------------|----------------------------------------------|
| `lmx:python`      | The module's default line, named on its page |
| `lmx:python-3.12` | The Python 3.12 line                         |

AstroNvim provides `lmx:astronvim-6` to select its major line.
Neovim and its plugins still come from the [base Nixpkgs revision](concepts.md#nixos-version-and-package-pins).
Git, Neovim and the other console components have no version selectors.

Docker, Node.js and AstroNvim lines fix the major version, allowing minor and patch updates in later catalog releases.
PostgreSQL lines also fix the major version, allowing minor updates within that major.
The other versioned modules fix major and minor, allowing only patch updates within a line.
A catalog release can also choose another default line.
For every versioned module, an explicit line replaces the unversioned recommendation.
This also works through Console or Cozy, without importing the recommended line alongside the chosen one.
Several explicit compatible lines coexist according to the module's documented policy; Docker and AstroNvim accept one line.

Lines marked as past their upstream end of life stay selectable.
Selecting one prints a warning when the VM is built, and the build continues:

```text
evaluation warning: Go 1.24.13 no longer receives upstream security updates.
```

Modules that track upstream support record its status in their release map and documentation.
When a tracked status has not been confirmed, the module page says it is unknown.
An unknown status emits no EOL warning; the absence of a warning does not confirm upstream support.
These statuses are reviewed when the catalog is maintained, not calculated from the current date during a VM build.

## Several versions in one VM

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

Each line adds commands with a version suffix, such as `python-3.12` and `python-3.14`.
Commands without a suffix, such as `python`, run the newest selected line.
Each module page lists its versioned commands.

Docker runs one system service.
Select only one Docker line per VM; see the [Docker page](../catalog/docker/README.md).
AstroNvim also accepts only one line.
An explicit selector overrides the default recommended by Console; see [AstroNvim versions](../catalog/astronvim/README.md#versions).

## Editor integration

The Go, Rust, Python and Node.js modules install language servers: `gopls`, `rust-analyzer`, Pyright and the JavaScript/TypeScript language server.
The plain Neovim module does not configure its LSP client.
[AstroNvim](../catalog/astronvim/README.md), also included in Console, enables the servers declared by selected language modules.

| Where the editor runs         | What connects it to the language server                                                                  |
|-------------------------------|----------------------------------------------------------------------------------------------------------|
| Inside the VM, such as Neovim | The editor's LSP client, configured to start the server                                                  |
| On your Mac                   | The editor's remote development support, connected to the VM with the project open at its path in the VM |

LimaNix does not set up remote editor connections; sharing a project directory with the VM shares only its files.

For software that the catalog does not provide, [write a module](writing-modules.md).
