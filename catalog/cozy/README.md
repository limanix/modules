# Cozy

`lmx:cozy` assembles a Linux development workbench with a shell, editor, common language toolchains, containers, local Kubernetes tools, cloud clients, and HTTP and SQL interfaces.
Its components remain separately selectable.

| Component | Provides |
|---|---|
| [Console](../console/README.md) | Zsh, tmux, AstroNvim, CLI tools, Lazygit, GitHub CLI and Yazi |
| [Docker](../docker/README.md) | Docker Engine, Compose and Lazydocker |
| [Minikube](../minikube/README.md) | Local Kubernetes command, matching kubectl through Minikube, and K9s |
| [Go](../go/README.md) | Go, gopls, Delve and GCC |
| [Python](../python/README.md) | Python, virtual environments and Pyright |
| [Node.js](../nodejs/README.md) | Node.js, npm, npx and JavaScript/TypeScript LSP |
| [Cloud tools](../cloud-tools/README.md) | AWS CLI v2 and Google Cloud CLI |
| [Posting](../posting/README.md) | Saved HTTP requests in a terminal interface |
| [Harlequin](../harlequin/README.md) | SQL interface with the Postgres adapter |

## Select the module

```toml
[nixos]
modules = ["lmx:cozy"]
```

Go, Python and Node.js are included with their language servers.
AstroNvim enables their declared servers and parsers.
Rust, Terraform, Helm and a PostgreSQL server remain separate choices.
An explicit supported component line overrides an aggregate recommendation according to that component's selection policy.
Allocate enough guest CPU, memory and disk for the workloads you run; the [project-workspace example](https://limanix.dev/categories/client/workspace.html#create-the-workbench) starts with 4 CPUs, 8 GiB memory and a 40 GiB disk.
Cozy follows component defaults and accepts explicit supported version selections.
Docker grants the VM user access through the `docker` group.

## Project workspace

Inside the VM, open a mounted project directory:

```console
tmux-project /workspace/my-project
```

Without an argument, the command uses the current directory.
It creates four windows: `editor` with AstroNvim, `shell`, `git` with Lazygit, and `containers` with Lazydocker.
Editor, Git and container windows open the configured shell after their application exits or when it cannot start.
The window remains available when a project is not a Git repository or Docker is unavailable.
Calling it again returns to the same session and preserves its running windows.
Session names contain a readable project basename and a hash of its physical path.
Projects with the same directory name remain separate; symlink aliases of the same physical directory reuse the session.
Inside tmux, the command switches the current client to the project session.

Use `Ctrl-b n` and `Ctrl-b p` to change windows and `Ctrl-b d` to detach.
Tmux keeps the session running while the VM remains up.
The [tmux page](../tmux/README.md) describes snapshot saving and restoration after a VM restart.
Project sessions and `limanix shell --session NAME` use the same tmux server, with different ways to select a session.

Run `y` in a Bash or Zsh shell to browse with Yazi and keep the selected directory when you exit.
Use `q` to apply the selected directory or `Q` to leave the shell's directory unchanged.
The shell, tmux, editor, Yazi and Lazygit default to Catppuccin Mocha.
The component pages describe personal configuration and managed overrides.

## API playground

Cozy installs a writable-project template as read-only files under `/etc/limanix/examples/cozy`.
Copy it into a new directory you want to experiment in:

```console
mkdir -p /workspace/cozy-notes
cp -R /etc/limanix/examples/cozy/. /workspace/cozy-notes/
chmod -R u+w /workspace/cozy-notes
cd /workspace/cozy-notes
docker compose up --build -d --wait
tmux-project .
```

The template contains a notes API, a Postgres database, saved Posting requests and a Harlequin connection profile.
Follow the [playground guide](playground/README.md) for the endpoints, database connection and shutdown commands.
These services start only when you run Compose in the copied project.
Minikube creates a cluster only when you run `minikube start`; cloud clients require your own authentication.
Cozy does not provision cloud resources.

Git identity, GitHub authentication and approval of project `.envrc` files remain personal configuration.
For icons and clipboard integration, configure the host terminal as described on the [Console page](../console/README.md#configuration-and-state).

## Versions

Cozy has no version lines.
Its component list and template belong to the catalog release.

## Configuration and integration

| Boundary | Contract |
|---|---|
| Settings | Owned by the imported components; no aggregate-specific public option namespace |
| Project interface | `tmux-project [directory]`; read-only example at `/etc/limanix/examples/cozy` |
| Personal state | Component configuration in the guest home; project files and copied playground in your chosen directory |
| Integration | Components share public contracts and default Mocha configuration |
| Services | Docker Engine is enabled; Kubernetes and playground services start only when requested |

## Corner cases

| Case | Behavior or next step |
|---|---|
| Missing project directory | Pass an existing mounted directory or run from it |
| Two projects share a basename | Physical-path session identity keeps them separate; symlink aliases reuse the same physical project |
| Git or Docker view is empty | The workspace does not create a repository or start containers |
| Reopening a workspace | Existing windows and processes are preserved rather than reset |
| VM restart | Save editor files and tmux layout first; snapshot restoration does not resume processes |

## Guarantees

| Guarantee | Covered by |
|---|---|
| Imports the component entry points listed above, with Docker user access and declared Go/Python/Node.js language support | `components.nix`, `check.nix` |
| Repeated component imports preserve the system and public settings | `tests.nix`: composition |
| `tmux-project [directory]` dispatches four project windows and reuses the physical-path session | `smoke.nix`: project |
| Tool windows remain available as shells after a tool exits, fails or is unavailable | `smoke.nix`: project |
| Project paths are passed literally and sessions can be selected from inside tmux | `smoke.nix`: project |
| Installs the notes API template; its HTTP operations use a real Postgres database | `check.nix`, `smoke.nix`: playground |
| Component configuration, themes and language integration remain owned by their modules | Component checks and `checks/integration.nix` |
