# Catalog

Each client bundles a catalog release. Select its modules by name to add tools
and services without writing Nix. This page lists the current checkout; your
client may bundle an older release.
[List available modules](https://limanix.dev/categories/client/modules.html#list-available-modules)
to check its selectors.

## Choose a composition

| Project needs | Module selection |
| -- | -- |
| Minimal guest or a custom setup | `modules = []` |
| Terminal work with a chosen toolchain | `["lmx:console", "lmx:go"]` |
| Container project | `["lmx:console", "lmx:docker"]` |
| Common development workbench | `["lmx:cozy"]` |
| Rust and infrastructure alongside Cozy | `["lmx:cozy", "lmx:rust", "lmx:terraform", "lmx:helm"]` |

Add your choices to the VM configuration:

```toml
[nixos]
modules = ["lmx:cozy"]
```

[Apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change),
then follow the selected module pages. Their `Use`,
`Configuration and integration`, `Corner cases` and `Guarantees` sections
describe commands, supported settings, state and checked behavior.

An empty selection retains the client's platform, account and mounts. Console
and Cozy assemble modules through public entry points; components remain
separately selectable. Cozy includes Go, Python and Node.js language support.
Other toolchains remain explicit choices. Cloud clients need authentication;
Minikube creates a cluster when you request it. The
[project workspace guide](https://limanix.dev/categories/client/workspace.html)
shows a complete workbench configuration.

## Modules

### Workspaces

| Module | Selector | Provides |
| -- | -- | -- |
| [Console](../catalog/console/README.md) | `lmx:console` | Zsh, tmux, AstroNvim, CLI tools and terminal applications |
| [Cozy](../catalog/cozy/README.md) | `lmx:cozy` | Project workbench, Console, common languages and LSP, Docker, Minikube, cloud, HTTP and SQL clients |

### Terminal and project tools

| Module | Selector | Provides |
| -- | -- | -- |
| [Zsh](../catalog/zsh/README.md) | `lmx:zsh` | Configured shell, prompt, history, completion and direnv |
| [tmux](../catalog/tmux/README.md) | `lmx:tmux` | Sessions, panes, clipboard and layout restoration |
| [AstroNvim](../catalog/astronvim/README.md) | `lmx:astronvim` | Configured Neovim with language-server integration |
| [Neovim](../catalog/neovim/README.md) | `lmx:neovim` | Neovim |
| [CLI tools](../catalog/cli-tools/README.md) | `lmx:cli-tools` | Search, previews, Git diffs, data and system tools |
| [Git](../catalog/git/README.md) | `lmx:git` | Git |
| [Lazygit](../catalog/lazygit/README.md) | `lmx:lazygit` | Git terminal interface |
| [GitHub CLI](../catalog/gh/README.md) | `lmx:gh` | GitHub repositories, pull requests and workflow runs |
| [Codex CLI](../catalog/codex/README.md) | `lmx:codex` | OpenAI coding agent in the terminal |
| [Claude Code](../catalog/claude/README.md) | `lmx:claude` | Anthropic coding agent in the terminal |
| [Yazi](../catalog/yazi/README.md) | `lmx:yazi` | Terminal file manager |
| [Posting](../catalog/posting/README.md) | `lmx:posting` | Saved HTTP requests in the terminal |
| [Harlequin](../catalog/harlequin/README.md) | `lmx:harlequin` | SQL terminal interface with the Postgres adapter |
| [Lazydocker](../catalog/lazydocker/README.md) | `lmx:lazydocker` | Docker terminal interface; also included by Docker |

### Languages

| Module | Selector | Provides |
| -- | -- | -- |
| [Go](../catalog/go/README.md) | `lmx:go` | Go, gopls, Delve, and GCC |
| [Node.js](../catalog/nodejs/README.md) | `lmx:nodejs` | Node.js, npm, npx and JavaScript/TypeScript LSP |
| [Python](../catalog/python/README.md) | `lmx:python` | Python, venv, virtualenv and Pyright LSP |
| [Rust](../catalog/rust/README.md) | `lmx:rust` | Rust toolchain, rust-analyzer, GCC, pkg-config, and GDB |

### Containers, cloud and infrastructure

| Module | Selector | Provides |
| -- | -- | -- |
| [Docker](../catalog/docker/README.md) | `lmx:docker` | Docker Engine, CLI, and Compose |
| [Minikube](../catalog/minikube/README.md) | `lmx:minikube` | Minikube for local Kubernetes clusters |
| [K9s](../catalog/k9s/README.md) | `lmx:k9s` | Terminal interface for Kubernetes |
| [Helm](../catalog/helm/README.md) | `lmx:helm` | Helm package manager for Kubernetes |
| [PostgreSQL](../catalog/postgres/README.md) | `lmx:postgres` | PostgreSQL server and tools for manual use |
| [Terraform](../catalog/terraform/README.md) | `lmx:terraform` | Terraform CLI for infrastructure as code |
| [AWS CLI](../catalog/aws/README.md) | `lmx:aws` | AWS CLI v2 |
| [Google Cloud CLI](../catalog/gcloud/README.md) | `lmx:gcloud` | Google Cloud CLI |

The Docker module gives the VM user root-equivalent access through the `docker`
group. Read its permissions and port-publishing guidance before using it.

Replace the former `lmx:cloud-tools` selector with
`modules = ["lmx:aws", "lmx:gcloud"]`. Cozy includes both modules.

## Versions

Versioned modules expose numeric lines in their metadata:

| Selector | Meaning |
| -- | -- |
| `lmx:python` | Recommend the Python module's metadata default |
| `lmx:python-3.12` | Select its supported 3.12 line explicitly |

An explicit line replaces a default recommendation, including one brought in by
Console or Cozy. A future catalog release may change the default. Read the
module's `Versions` section for exact package versions and what its line fixes;
a line can represent a major or a major/minor choice. Modules without lines have
only their unversioned selector.

Support status is also module-owned. Follow the module page's upstream policy
links and any documented end-of-life warnings. An unknown status or absence of a
warning does not establish upstream support. Removing a selectable line requires
a catalog release with migration notes. See
[Catalog compatibility](concepts.md#catalog-compatibility) for how client and
catalog releases relate.

## Several versions in one VM

Select several explicit lines only when the module documents coexistence. For
example, [Python](../catalog/python/README.md#several-versions) supports:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

The Python page explains its versioned commands, virtual environments and which
interpreter runs as `python`. Command names, priorities, services and data
belong to each module's policy. Other modules may require a single line; see
[Docker](../catalog/docker/README.md#versions) and
[AstroNvim](../catalog/astronvim/README.md#versions). An unsupported combination
fails with the module's diagnostic rather than silently dropping a line.

## Editor integration

Go, Rust, Python and Node.js provide language servers and publish them through
`lmx.capabilities.languageSupport`. This public schema connects providers to
editors that consume it. [AstroNvim](../catalog/astronvim/README.md), also
included in Console, configures the declared servers. The
[Neovim module](../catalog/neovim/README.md#language-servers) leaves LSP
configuration to you.

| Where the editor runs | How it connects |
| -- | -- |
| Inside the VM | Its LSP client starts the selected server |
| On your Mac | Its remote development support connects to the VM and opens the project's guest path |

Sharing a directory shares files; remote editor setup remains your choice. See
[Connect modules](concepts.md#connect-modules) for dependencies and
capabilities.

For software or settings beyond this catalog,
[write a module](writing-modules.md).
