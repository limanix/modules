# Repository automation

Automation consumes the public module contract. It does not inspect private
package maps or choose module-specific test scenarios.

| Layer                | Responsibility                                                                      |
| -------------------- | ----------------------------------------------------------------------------------- |
| Workflow             | Events, change selection, native matrices, cache restore/save and the required gate |
| Taskfile             | The same explicit commands for local use and CI                                     |
| `plan_checks.py`     | Git diff to modules, public-import consumers and shared/documentation flags         |
| `run_checks.sh`      | Contract validation, stage execution, build permission and deadlines                |
| `cache_nix_build.sh` | Optional export of completed build closures                                         |

Module scenarios stay in each module's `test.nix` and private `test/` files. The
runner implements their common calling and result contract.

## PR flow

Pull requests and pushes to `main` use the same check flow:

```mermaid
flowchart LR
    plan[Plan modules] --> test[Test: module × architecture]
    plan --> common[Common: architecture]
    lint[Lint] --> gate[Required gate]
    test --> gate
    common --> gate
```

| Job      | Work                                                   | Selection                                                                  |
| -------- | ------------------------------------------------------ | -------------------------------------------------------------------------- |
| `plan`   | Git diff and public dependency discovery               | Every run                                                                  |
| `lint`   | Nixfmt, Statix, Deadnix and source Markdown formatting | Every run                                                                  |
| `test`   | One module: `eval`, then `run`                         | Changed modules and their consumers, on x86 and ARM                        |
| `common` | Shared and platform `eval`/`run`                       | Shared, interface, base pin, harness or automation changes, on x86 and ARM |
| `gate`   | Require all selected jobs to succeed                   | Every run                                                                  |

There is no barrier between all module evaluations and all native runs. Each
module job completes its own cycle. Documentation-only changes run planning and
lint; module and common jobs are skipped. A new push cancels the previous run of
the same pull request. Runs on `main` are never cancelled, so each one tests and
caches its own changes.

The planner discovers module directories. Contract validation belongs to the
harness. Dependency discovery evaluates public default and version entry points
for both architectures. It does not run module tests or infer imports by reading
private files. If discovery is unavailable, the planner selects the full
catalog. Shared or unknown repository source changes also select the full
catalog and common checks.

## Run locally

From the repository root, with Task and Docker:

```console
task --yes ci/lint
task --yes ci/test/modules MODULES=dev-tools
task --yes ci/test/common
```

`dev-tools` is the illustrative entry in [Write a module](writing-modules.md);
replace it with a module present in your checkout. `MODULES` accepts
space-separated directory names. Omitting it selects the full catalog. Each
selected module has its own deadline for the combined `eval` and `run` cycle.
The combined common cycle has one deadline for shared and platform checks.

`ci/test/modules` defaults to `MODE=check`. `ci/test/common` defaults to
`SUITE=common` and `MODE=check`. Select an individual suite or stage when
diagnosing a failure or running release checks:

| Task                                          | Result                                                                              |
| --------------------------------------------- | ----------------------------------------------------------------------------------- |
| `ci/test/modules MODE=eval MODULES=dev-tools` | Metadata, entry points, recommendation, Boolean assertions and expected diagnostics |
| `ci/test/modules MODE=run MODULES=dev-tools`  | Native execution after the local-build dry-run                                      |
| `ci/test/common SUITE=shared MODE=eval`       | Shared schemas and test helpers                                                     |
| `ci/test/common SUITE=platform MODE=run`      | Native builder permissions                                                          |

On native Linux, the same runner is available directly:

```console
bash scripts/run_checks.sh module check dev-tools
bash scripts/run_checks.sh common check
```

A module's activation check needs native Linux and an accessible `/dev/kvm`:

```console
task --yes ci/test/modules MODE=vm MODULES=dev-tools CONTAINER_RUN_ARGS=--device=/dev/kvm
```

A container without KVM cannot prove activation.

Discovery commands:

```console
task --yes ci/plan/dependencies SYSTEM=aarch64-linux OUTPUT=build/dependencies.json
task --yes ci/plan/vm-modules SYSTEM=aarch64-linux OUTPUT=build/vm-modules.json
```

`SYSTEM` also accepts `x86_64-linux`; omitted values use the native runner.

## Caches

Each native job restores one cache for its target (a module or the common suite)
and architecture. It holds downloaded sources in `.cache/nix` and the target's
own local builds in `.cache/nix-binary`. Successful runs on `main`, pushes and
manual runs, save it; pull requests and tags only restore it. Cache failures do
not replace check results.

The key combines the architecture, the target and a hash of `flake.lock`,
`flake.nix`, `interface.nix`, `catalog/**`, `checks/**`, `run_checks.sh` and
`cache_nix_build.sh`. Restore tries the exact key first, then the newest cache
for the same architecture and target. Parallel jobs with the same key do not
merge their archives. Local builds reach the cache through an explicit
post-build hook with a small fixed storage guard. An existing exact archive is
read without adding another export.

The module's `builds` export permits exact artifacts. The harness includes
permissions from selected modules and their default/individual-line public-entry
dependencies. A test-only import does not extend this set or schedule another
module's checks. An uncached dependency outside the
[local-build policy](catalog-contract.md#local-builds-and-runtime) fails the
dry-run. Restoring a cache does not expand build permission.

## Deadlines and evidence

| CI check                                                                   | Runner deadline | Check-step cap | Job cap    |
| -------------------------------------------------------------------------- | --------------- | -------------- | ---------- |
| Module `eval` + `run`, combined common checks, or an explicit native stage | 7 minutes       | 8 minutes      | 10 minutes |
| Release VM                                                                 | 12 minutes      | 13 minutes     | 15 minutes |

`NIX_CHECK_TIMEOUT` sets the runner deadline. For several selected modules it
starts again for each module; it covers both stages when using `check`. CI uses
one build job and all available cores for that build. These limits bound work;
they are not measured runtime guarantees.

Reports identify the suite, stage, architecture, actual duration and result.
Separate new execution from reused results where known. A cache hit or printed
derivation path does not prove a fresh run. Unknown cache state stays unknown.
VM status is passed, failed or not run, with the reason for unavailable KVM.

## Other automation

`build_docs.py` prepares source Markdown for the documentation site.
`nixpkgs/update` remains an explicit local command. The release flow runs the
same `check` cycle for every module and the common suite, then the modules' VM
tests.

Each module declares additional revisions in `lmx.pins`. Shared
`_module.args.pinned` resolves one lazy package set per revision within that
system, using its architecture and unfree policy. Automation has no named-module
snapshot registry.
