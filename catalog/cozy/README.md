# Cozy

`lmx:cozy` assembles a Linux development workbench with a shell, editor, task
runner, common language toolchains, containers, local Kubernetes tools, cloud
clients, and HTTP and SQL interfaces. Its components remain separately
selectable.

| Component | Provides |
| -- | -- |
| [Console](../console/README.md) | Zsh, tmux, AstroNvim, CLI tools, Lazygit, GitHub CLI and Yazi |
| [Taskfile](../taskfile/README.md) | Task runner for the tasks a project declares in its `Taskfile.yml` |
| [Docker](../docker/README.md) | Docker Engine, Compose and Lazydocker |
| [Minikube](../minikube/README.md) | Local Kubernetes command, matching kubectl through Minikube, and K9s |
| [Go](../go/README.md) | Go, gopls, Delve and GCC |
| [Python](../python/README.md) | Python, virtual environments and Pyright |
| [Node.js](../nodejs/README.md) | Node.js, npm, npx and JavaScript/TypeScript LSP |
| [AWS CLI](../aws/README.md) | AWS CLI v2 |
| [Google Cloud CLI](../gcloud/README.md) | Google Cloud CLI |
| [Posting](../posting/README.md) | Saved HTTP requests in a terminal interface |
| [Harlequin](../harlequin/README.md) | SQL interface with the Postgres adapter |

## Select the module

```toml
[nixos]
modules = ["lmx:cozy"]
```

Go, Python and Node.js are included with their language servers. AstroNvim
enables their declared servers and parsers. Rust, Terraform, Helm and a
PostgreSQL server remain separate choices. An explicit supported component line
overrides an aggregate recommendation according to that component's selection
policy. Allocate enough guest CPU, memory and disk for the workloads you run;
the
[project-workspace example](https://limanix.dev/categories/client/workspace.html#create-the-workbench)
starts with 4 CPUs, 8 GiB memory and a 40 GiB disk. Cozy follows component
defaults and accepts explicit supported version selections. Docker grants the VM
user access through the `docker` group.

## Project workspace

Inside the VM, open a mounted project directory:

```console
tmux-project /workspace/my-project
```

Without an argument, the command uses the current directory. It creates four
windows: `editor` with AstroNvim, `shell`, `git` with Lazygit, and `containers`
with Lazydocker. Editor, Git and container windows open the configured shell
after their application exits or when it cannot start. The window remains
available when a project is not a Git repository or Docker is unavailable.
Calling it again returns to the same session and preserves its running windows.
Session names contain a readable project basename and a hash of its physical
path. Projects with the same directory name remain separate; symlink aliases of
the same physical directory reuse the session. Inside tmux, the command switches
the current client to the project session.

Use `Ctrl-b n` and `Ctrl-b p` to change windows and `Ctrl-b d` to detach. Tmux
keeps the session running while the VM remains up. The
[tmux page](../tmux/README.md) describes snapshot saving and restoration after a
VM restart. Project sessions and `limanix shell --session NAME` use the same
tmux server, with different ways to select a session.

Run `y` in a Bash or Zsh shell to browse with Yazi and keep the selected
directory when you exit. Use `q` to apply the selected directory or `Q` to leave
the shell's directory unchanged. The shell, tmux, editor, Yazi and Lazygit use
the guest's theme: Catppuccin Mocha, unless `[theme]` in `limanix.toml` selects
another flavor. The component pages describe personal configuration and managed
overrides.

## Project services

Run Compose from your project's directory when you need its containers. Minikube
creates a cluster when you run `minikube start`; cloud clients require your own
authentication. Cozy does not provision cloud resources.

Git identity, GitHub authentication and approval of project `.envrc` files
remain personal configuration. For icons and clipboard integration, configure
the host terminal as described on the
[Console page](../console/README.md#configuration-and-state).

## Versions

Cozy has no version lines. Its component list and workspace command belong to
the catalog release.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Owned by the imported components; no aggregate-specific public option namespace |
| Project interface | `tmux-project [directory]` |
| Personal state | Component configuration in the guest home; project files in your chosen directory |
| Integration | Components share public contracts and the guest's theme |
| Services | Docker Engine is enabled; project containers and Kubernetes clusters start when requested |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Missing project directory | Pass an existing mounted directory or run from it; the command exits with status 1 |
| Two projects share a basename | Physical-path session identity keeps them separate; symlink aliases reuse the same physical project |
| Git or Docker view is empty | The workspace does not create a repository or start containers |
| Reopening a workspace | Existing windows and processes are preserved |
| VM restart | Save editor files and tmux layout first; snapshot restoration does not resume processes |
| Piped command without a terminal | Run `tmux-project` in an interactive terminal; attaching requires a terminal |
| More than one directory argument | The command prints usage and exits with status 64 |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Go, Python and JavaScript/TypeScript providers publish and install language support | `eval.languageSupport` |
| Enables Docker Engine and adds the VM user to its access group | `eval.dockerAccess` |
| Installs the project-workspace command | `eval.workspace` |
| Development and cloud commands run from the selected system profile | `run.commands` |
| Real project windows preserve literal paths and physical identity, support reattachment and client switching | `run.workspace` |
| Real editor, Git and container windows retain a shell after application exit | `run.workspace` |
| Invalid arguments fail without changing existing sessions | `run.workspace` |
| Installs no bundled example applications | `eval.noExamples` |
