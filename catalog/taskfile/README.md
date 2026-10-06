# Taskfile

Installs the Task runner, which executes the tasks a project declares in its
`Taskfile.yml`.

```toml
[nixos]
modules = ["lmx:taskfile"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:taskfile` recommends the catalog default. An explicit `lmx:taskfile-LINE`
selection replaces that recommendation. Multiple explicit supported lines retain
the side-by-side behavior described below.

| Selector | Task | Notes |
| -- | -- | -- |
| `lmx:taskfile`, `lmx:taskfile-3.53` | 3.53.1 | Default |
| `lmx:taskfile-3.52` | 3.52.0 |  |
| `lmx:taskfile-3.48` | 3.48.0 |  |

Upstream ships fixes in its newest release and publishes no support policy for
older minor lines. The catalog records their
[EOL status](../../guides/catalog.md#versions) as unknown and does not emit an
EOL warning for them.

## Use

Inside the VM, show the installed Task version:

```console
task --version
```

List the tasks a project declares and run one of them:

```console
task --list
task build
```

Each line also installs Task's own `go-task` alias for the same executable.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:taskfile-3.48", "lmx:taskfile-3.53"]
```

Each line adds a command with its version:

```console
task-3.48 --version
task-3.53 --version
```

`task` and `go-task` run the newest selected line.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Project `Taskfile.yml`, its includes and native Task environment variables such as `TASK_TEMP_DIR` |
| Personal state | Project `.task/` fingerprint directory and whatever the tasks themselves write |
| Integration | The programs a task calls and any included taskfiles are configured by the project |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| A task calls a missing program | Select the module that installs it; this module installs the runner, not the project's tools |
| Remote taskfile includes | Task gates them behind its own experiment and prompt; enable them per project and review the fetched source |
| Stale `status` or `sources` results | Remove the project's `.task/` directory or run the task with `--force` |
| Several versions | Use versioned commands with a `Taskfile.yml` whose declared schema that line accepts |

## Local builds

The module declares exact build permissions for each runner and its vendor
inputs:

| Line | Runner | Vendor inputs |
| -- | -- | -- |
| 3.48 | `builds.task-3.48` | `builds.task-vendor-3.48` |
| 3.52 | `builds.task-3.52` | `builds.task-vendor-3.52` |
| 3.53 | `builds.task-3.53` | `builds.task-vendor-3.53` |

These permissions do not execute tests or cover dependencies. An uncached
compiler or another dependency fails the runtime dry-run; populate its cache
before running the checks.

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Each Task line installs its package with the expected warning behavior | `eval.line-3.48`, `eval.line-3.52`, `eval.line-3.53` |
| Selected lines coexist; the newest package supplies `task` and `go-task` | `eval.allLines`, `run.allLines` |
| Versioned commands list the project's tasks and run one with its variables and dependencies | `run.commands-3.48`, `run.commands-3.52`, `run.commands-3.53` |

No test fetches a remote taskfile; the fixture declares every command it runs.
