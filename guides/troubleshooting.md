# Troubleshooting

Use this page to investigate module errors, package builds, programs and services, and catalog checks.
For failed imports, VMs that do not start, and interrupted updates, see the client's [Troubleshooting](https://limanix.dev/categories/client/troubleshooting.html).

## Read the error

Keep the complete diagnostic, including the surrounding trace and any file paths, line numbers, or option names.
Identify the stage that failed before changing the module:

| What failed                                             | Start with                                      |
|---------------------------------------------------------|-------------------------------------------------|
| Reading Nix code or evaluating an option                | [Module errors](#module-errors)                 |
| Downloading or building a package or project dependency | [Build failures](#build-failures)               |
| Running an installed command or service                 | [Programs and services](#programs-and-services) |
| Validating an entry with the repository's checks        | [Catalog checks](#catalog-checks)               |

For Nix evaluation errors, read the reported expression and the context explaining which option or module led to it.
For build failures, find the failing package's diagnostic rather than only a later summary that a dependency failed.
If a source path points into `/nix/store`, use it to identify the file, but edit your module's source, not the store copy.

## Module errors

The messages below identify what to investigate; they do not always have a single cause.

| Message contains                                             | What to check                                                                    | Next step                                                                                                                                                                                                          |
|--------------------------------------------------------------|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `syntax error, unexpected`                                   | Punctuation and expression structure at the reported location and just before it | Check semicolons, brackets, and quotes against the [module examples](writing-modules.md#create-a-module)                                                                                                           |
| `undefined variable 'pkgs'`                                  | Whether `pkgs` is in scope where it is used                                      | If the module needs the package set, request it with `{ pkgs, ... }:`                                                                                                                                              |
| `attribute '…' missing`                                      | Which set is missing the field: `pkgs`, `config`, or another value              | Check the field name and the set it belongs to; use [package search](https://search.nixos.org/packages) for `pkgs` and the [module migration table](writing-modules.md#migrate-custom-modules) for previous `runtime` or `inputs` references |
| `The option … does not exist`                                | The option name and whether its declaring module is included                     | Check [option search](https://search.nixos.org/options) for built-in options, or the module that declares a custom option                                                                                          |
| `is not of type`                                             | The expected type and the definition value printed in the error                  | Match the option's type; for example, Boolean `true` is not the string `"true"`                                                                                                                                    |
| `has conflicting definition values`                          | The definitions and their source files listed in the error                       | Remove an unintended assignment or use an intentional override; see [Combine with other modules](writing-modules.md#combine-with-other-modules)                                                                    |
| `is defined multiple times while it's expected to be unique` | Multiple definitions of an option that permits only one                          | Keep one definition, as when choosing one [Docker version](../catalog/docker/README.md#versions)                                                                                                                   |
| `path '…' does not exist`                                    | The spelling, relative path, and presence of the referenced file                 | Resolve relative paths from the file that contains them; keep [imported files](writing-modules.md#split-a-module-into-files) inside the module directory                                                           |
| `infinite recursion encountered`                             | Values that depend on each other while the configuration is being evaluated      | Use [`lib.mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) for conditional option definitions; other cycles need their dependencies corrected                           |

Search packages and built-in options in the [NixOS release pinned by the catalog](concepts.md#nixos-version-and-package-pins).
An option or package shown for another release may not be available in that pin.

## Build failures

### Nix package builds

Find the failing package's `.drv` path in the output.
Run [`nix log`](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-log.html) with that path in the environment where the build ran: inside the VM for a guest build.
The command shows the build log if it is available locally or from a configured binary cache.

For a compiler or test failure, read the package's log for the specific error.
For a failed download, check the reported URL and network error before retrying.
If the error reports a hash mismatch, verify the intended source revision and hash; do not replace the pin just to silence the error.

### Project dependency builds

When pip, npm, or another project tool builds a dependency inside the VM, inspect that tool's output:

| Message contains                             | What to check                                                    |
|----------------------------------------------|------------------------------------------------------------------|
| `gcc: command not found`                     | Whether the required compiler is available to the build command  |
| `fatal error: …h: No such file or directory` | The library's development files and the compiler's include paths |
| `No package '…' found` from pkg-config       | The library's `.pc` files and `PKG_CONFIG_PATH`                  |

[Build tools and libraries](writing-modules.md#build-tools-and-libraries) shows how to provide these dependencies and check them with pkg-config.
For a failure inside a Nix package build, inspect that package's declared build dependencies rather than adding tools to the VM.

## Programs and services

Run these diagnostic commands inside the VM where the module's configuration is applied.

### A command fails or runs the wrong version

| Symptom                                         | What to check                                                                         | Next step                                                                                                                           |
|-------------------------------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `command not found`                             | The command's name, installed package, and shell search path                          | Check the module's documented commands; for example, `pkgs.ripgrep` provides `rg`                                                   |
| An unexpected version runs                      | Which executable the shell finds, including virtual environments and version managers | Inspect the path below; if system packages compete, see [Combine with other modules](writing-modules.md#combine-with-other-modules) |
| `Could not start dynamically linked executable` | Whether the downloaded binary expects a loader outside `/nix/store`                   | See [Downloaded programs](writing-modules.md#downloaded-programs)                                                                   |
| `cannot open shared object file`                | Which library is missing and which program is loading it                              | For pip or npm extensions, see [Native extensions](writing-modules.md#native-extensions-in-python-and-nodejs)                       |
| `Exec format error`                             | The executable's format and target architecture                                       | Use a valid Linux executable matching the VM's architecture; for a script, check its interpreter line                               |

For example, inspect which `go` executable the shell finds:

```console
command -v go
```

If it returns a file path, resolve its symlinks to see the target:

```console
readlink -f "$(command -v go)"
```

Replace `go` with the failing command.
If the first command reports an alias or function, inspect that definition instead.
Go can also download another toolchain after it starts; see [Toolchain downloads](../catalog/go/README.md#toolchain-downloads) when the executable path alone does not explain its version.

### A service does not start

Check the service's status and journal, for example for the [PostgreSQL module example](writing-modules.md#enable-a-service):

```console
systemctl status postgresql.service --no-pager
journalctl -b -u postgresql.service --no-pager
```

Replace `postgresql.service` with the unit you are investigating.
The first command shows its current state; the second shows its journal for the current boot.
An account without access to the system journal may need an administrator to read those logs.

- If the unit is not found, check that the service option is enabled in the applied configuration, not just that its package is installed.
- If it is failed, use the exit status and journal to identify the startup error, such as a configuration problem, missing file, or occupied port.
- If it is active but the application still fails, inspect the application's own diagnostics; a running process alone does not confirm that it is working correctly.

The [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-systemctl) describes service status and logs in more detail.

## Catalog checks

This section applies when contributing entries to this repository, not to every custom module.
Keep the `while checking … on …` context: it identifies the entry or combination and the architecture under evaluation.

| Diagnostic                                                                          | What to check                                                           | Next step                                                                                                                              |
|-------------------------------------------------------------------------------------|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `Module catalog:`                                                                   | The named entry's files, metadata, or selector collision                | Follow the specific message and the [metadata rules](writing-modules.md#follow-the-metadata-rules)                                     |
| `Module result:` | The named module's configuration assertion | Compare `check.nix` or `tests.nix` with the evaluated settings; see [Write the result check](writing-modules.md#write-the-result-check) |
| `Module smoke:` | The returned checks and their target system | Inspect the module's `smoke.nix` and the reported check |
| `Common contract:` | A shared declaration or capability-schema assertion | Inspect the named fixture in [checks/common.nix](../checks/common.nix) |
| `Catalog integration:` | A full-catalog or intermodule assertion | Inspect the named combination in [checks/integration.nix](../checks/integration.nix) |
| `Catalog base:`                                                                     | The root Nixpkgs input and lock file                                    | Follow the diagnostic and [Update the NixOS base](writing-modules.md#update-the-nixos-base)                                            |
| `Killed` or exit status `137` | The Linux runner's memory limit and kernel log | Confirm whether the kernel killed an evaluator for memory pressure; see [Validation memory](#validation-memory) |
| `assertion … failed` in an entry's `packages.nix`                                   | The assertion at the reported line, including expected package versions | Check the [release map and package loader](writing-modules.md#support-multiple-versions) together                                      |

Run the tasks in the repository's [Taskfile](../Taskfile.yml) from the repository root.
Select the modules involved in the failure:

```console
task --yes ci/test MODULES="go rust"
```

`ci/test` evaluates every supported line of the selected modules, verifies expected diagnostics and runs profile-selected native smoke.
Omitting `MODULES` selects every module; local runtime defaults to `all`.
Module evaluation and smoke instantiation reuse the same configurations.
The PR runtime profile retains current/default startup and override corners plus requested lines; strong compatibility evaluation remains complete.
To reproduce current runtime plus one changed line:

```console
task --yes ci/test MODULES=go RUNTIME_PROFILE=pr RUNTIME_VERSIONS="1.26"
```

Additional lines must be declared, space-separated numeric versions for exactly one selected module.
Use `RUNTIME_PROFILE=all` for all historical runtime checks, including the named `coexistence` check.
The PR planner adds changed declared numeric version lines to current runtime.
Other non-document pod changes, including metadata and release maps, use full runtime for that pod and its transitive consumers.
`ci/common` uses `MODE=pr` by default to check metadata and shared interfaces through small fixtures.
Use release mode to investigate full-catalog and intermodule failures:

```console
task --yes ci/common MODE=release
```

Release mode combines full-catalog evaluation with AstroNvim LSP integration smoke.
Use `MODE=release-eval` or `MODE=release-smoke` to isolate those stages.
The ten-minute goal reports slow successful checks without failing them.
`NIX_CHECK_TARGET_SECONDS` defaults to 600 seconds; the output includes evaluation, diagnostic and build/runtime timings.
The separate `NIX_CHECK_TIMEOUT` runaway guard defaults to 1800 seconds locally and in native CI.
If that guard fires, inspect the last active phase, dependency downloads and cache availability. Preserve full tests when adjusting it for a cold build.
Both tasks use the container's native Linux architecture and identify it in their output.
These checks do not boot a complete Lima VM.
A passing check does not replace testing the module's documented commands in a VM.

### Validation memory

Full native module evaluation, including historical version lines, can need close to 8 GiB per evaluator.
Selecting `RUNTIME_PROFILE=pr` reduces native build/run work while retaining the full compatibility evaluation and its memory needs.
The local runner defaults to `NIX_CHECK_JOBS=1` and evaluates one module at a time.
Avoid running separate module suites in parallel on an 8 GiB Linux runner.
Allow about 12 GiB for heavy whole-catalog validation and additional memory when increasing concurrency or building large packages.
These evaluation and build requirements are separate from the memory used by the installed development tools.
The 8 GiB [Cozy example](https://limanix.dev/categories/client/workspace.html#create-the-workbench) remains the starting point for ordinary project development.

To repeat one module with explicit serial execution:

```console
task --yes ci/test MODULES=rust CONTAINER_ENVS="NIX_CHECK_JOBS=1"
```

Replace `rust` with the failing module.
Give the Docker or VM Linux runner the memory allocation, rather than relying only on the Mac's total memory.
Check its kernel log to confirm an out-of-memory kill before treating exit status 137 as a memory diagnosis.

## Warnings

The catalog emits a warning for version lines marked end of life, for example:

```text
evaluation warning: Docker Engine 28.5.2 no longer receives upstream security updates.
```

This warning is separate from a build error.
Use a supported line listed on the module's page; if the build also fails, investigate its error separately.
