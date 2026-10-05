# Troubleshooting

Use this page to investigate module errors, package builds, programs and
services, and catalog checks. For failed imports, VMs that do not start, and
interrupted updates, see the client's
[Troubleshooting](https://limanix.dev/categories/client/troubleshooting.html).

## Read the error

Keep the complete diagnostic, including the surrounding trace and any file
paths, line numbers, or option names. Identify the stage that failed before
changing the module:

| What failed | Start with |
| -- | -- |
| Reading Nix code or evaluating an option | [Module errors](#module-errors) |
| Downloading or building a package or project dependency | [Build failures](#build-failures) |
| Running an installed command or service | [Programs and services](#programs-and-services) |
| Validating an entry with the repository's checks | [Catalog checks](#catalog-checks) |

For Nix evaluation errors, read the reported expression and the context
explaining which option or module led to it. For build failures, find the
failing package's diagnostic rather than only a later summary that a dependency
failed. If a source path points into `/nix/store`, use it to identify the file,
but edit your module's source, not the store copy.

## Module errors

The messages below identify what to investigate; they do not always have a
single cause.

| Message contains | What to check | Next step |
| -- | -- | -- |
| `syntax error, unexpected` | Punctuation and expression structure at the reported location and just before it | Check semicolons, brackets, and quotes against the [module examples](writing-modules.md#create-a-module) |
| `undefined variable 'pkgs'` | Whether `pkgs` is in scope where it is used | If the module needs the package set, request it with `{ pkgs, ... }:` |
| `attribute '…' missing` | Which set is missing the field: `pkgs`, `config`, or another value | Check the field name and the set it belongs to; use [package search](https://search.nixos.org/packages) for `pkgs` and the [module migration table](writing-modules.md#migrate-custom-modules) for previous `runtime` or `inputs` references |
| `The option … does not exist` | The option name and whether its declaring module is included | Check [option search](https://search.nixos.org/options) for built-in options, or the module that declares a custom option |
| `is not of type` | The expected type and the definition value printed in the error | Match the option's type; for example, Boolean `true` is not the string `"true"` |
| `has conflicting definition values` | The definitions and their source files listed in the error | Remove an unintended assignment or use an intentional override; see [Combine with other modules](writing-modules.md#combine-with-other-modules) |
| `is defined multiple times while it's expected to be unique` | Multiple definitions of an option that permits only one, such as two modules setting `limanix.user.shell` | Keep one definition, or give the intended one a higher priority; see [Read VM user settings](writing-modules.md#read-vm-user-settings) |
| `<module>: select one line` | Several explicit lines of a module that supports only one | Keep one selector; see that module's `Versions` section, such as [Docker](../catalog/docker/README.md#versions) |
| `path '…' does not exist` | The spelling, relative path, and presence of the referenced file | Resolve relative paths from the file that contains them; keep [imported files](writing-modules.md#split-a-module-into-files) inside the module directory |
| `infinite recursion encountered` | Values that depend on each other while the configuration is being evaluated | Use [`lib.mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) for conditional option definitions; other cycles need their dependencies corrected |

Search packages and built-in options in the
[NixOS release pinned by the catalog](concepts.md#nixos-version-and-package-pins).
An option or package shown for another release may not be available in that pin.

## Build failures

### Nix package builds

Find the failing package's `.drv` path in the output. Run
[`nix log`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-log.html)
with that path in the environment where the build ran: inside the VM for a guest
build. The command shows the build log if it is available locally or from a
configured binary cache.

For a compiler or test failure, read the package's log for the specific error.
For a failed download, check the reported URL and network error before retrying.
If the error reports a hash mismatch, verify the intended source revision and
hash; do not replace the pin just to silence the error.

### Project dependency builds

When pip, npm, or another project tool builds a dependency inside the VM,
inspect that tool's output:

| Message contains | What to check |
| -- | -- |
| `gcc: command not found` | Whether the required compiler is available to the build command |
| `fatal error: …h: No such file or directory` | The library's development files and the compiler's include paths |
| `No package '…' found` from pkg-config | The library's `.pc` files and `PKG_CONFIG_PATH` |

[Build tools and libraries](writing-modules.md#build-tools-and-libraries) shows
how to provide these dependencies and check them with pkg-config. For a failure
inside a Nix package build, inspect that package's declared build dependencies
rather than adding tools to the VM.

## Programs and services

Run these diagnostic commands inside the VM where the module's configuration is
applied.

### A command fails or runs the wrong version

| Symptom | What to check | Next step |
| -- | -- | -- |
| `command not found` | The command's name, installed package, and shell search path | Check the module's documented commands; for example, `pkgs.ripgrep` provides `rg` |
| An unexpected version runs | Which executable the shell finds, including virtual environments and version managers | Inspect the path below; if system packages compete, see [Combine with other modules](writing-modules.md#combine-with-other-modules) |
| `Could not start dynamically linked executable` | Whether the downloaded binary expects a loader outside `/nix/store` | See [Downloaded programs](writing-modules.md#downloaded-programs) |
| `cannot open shared object file` | Which library is missing and which program is loading it | For pip or npm extensions, see [Native extensions](writing-modules.md#native-extensions-in-python-and-nodejs) |
| `Exec format error` | The executable's format and target architecture | Use a valid Linux executable matching the VM's architecture; for a script, check its interpreter line |

For example, inspect which `go` executable the shell finds:

```console
command -v go
```

If it returns a file path, resolve its symlinks to see the target:

```console
readlink -f "$(command -v go)"
```

Replace `go` with the failing command. If the first command reports an alias or
function, inspect that definition instead. Go can also download another
toolchain after it starts; see
[Toolchain downloads](../catalog/go/README.md#toolchain-downloads) when the
executable path alone does not explain its version.

### A service does not start

Check the service's status and journal, for example for the
[PostgreSQL module example](writing-modules.md#enable-a-service):

```console
systemctl status postgresql.service --no-pager
journalctl -b -u postgresql.service --no-pager
```

Replace `postgresql.service` with the unit you are investigating. The first
command shows its current state; the second shows its journal for the current
boot. An account without access to the system journal may need an administrator
to read those logs.

- If the unit is not found, check that the service option is enabled in the
  applied configuration, not just that its package is installed.
- If it is failed, use the exit status and journal to identify the startup
  error, such as a configuration problem, missing file, or occupied port.
- If it is active but the application still fails, inspect the application's own
  diagnostics; a running process alone does not confirm that it is working
  correctly.

The [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-systemctl)
describes service status and logs in more detail.

## Catalog checks

Keep the complete module, suite, stage, architecture and test-key context from
the failing command. Find the first concrete error, rather than a later summary
that its dependency failed.

| Failure | Inspect | Next step |
| -- | -- | -- |
| Metadata or selector validation | `module.toml` and public entry points | Follow the [metadata rules](writing-modules.md#follow-the-metadata-rules) |
| Configuration assertion or non-Boolean result | `eval.<key>` from the public `test.nix` | Inspect the owning fixture under `test/`; configuration checks must return `true` |
| Expected refusal succeeds or has a different message | `fails.<key>.modules` and `message` | Use the intended public entries; a timeout or unrelated failure is not the expected diagnostic |
| Unexpected local build | Reported `.drv` paths and `builds` export | Identify the actual uncached artifact; exact permission does not cover its dependencies |
| Native command failure | `run.<key>` log and selected profile | Read the command assertion and its temporary fixture; see [Write the result check](writing-modules.md#write-the-result-check) |
| Wrong architecture | Runner system and derivation system | Use native Linux matching the declared test architecture |
| KVM unavailable | Host virtualization and `/dev/kvm` access | Use native Linux with KVM; record the activation test as not run |
| Activation assertion | `vm.activation` driver and guest journal | Inspect the module-owned scenario and actual service/login state |
| `Killed` or status `137` | Runner limits and kernel log | Confirm an OOM kill before attributing it to memory |

From the repository root, repeat the combined check or isolate the failing
stage:

```console
task --yes ci/test/modules MODULES=dev-tools
task --yes ci/test/modules MODE=eval MODULES=dev-tools
task --yes ci/test/modules MODE=run MODULES=dev-tools
```

Replace `dev-tools` with an existing module. `MODULES` contains space-separated
directory names; omitting it selects the catalog. The public module export
contains its line and feature checks. The runner sets no time limits. When a
check hangs, repeat that one module and stop it by hand; an interrupted run is
incomplete evidence.

For shared and platform checks:

```console
task --yes ci/test/common
task --yes ci/test/common SUITE=shared MODE=eval
task --yes ci/test/common SUITE=platform MODE=run
```

`ci/test/common` runs shared, then platform, each with `eval` and then `run`.
`MODE=eval` and `MODE=run` need `SUITE=shared` or `SUITE=platform`; the combined
suite accepts only `check`. The same CLI on native Linux is
`bash scripts/run_checks.sh SUITE MODE [module names]`; use `module check` or
`common check` for the combined checks. An activation check uses `module vm` and
needs KVM; CI does not run it. With Task on that native Linux host, pass
`CONTAINER_RUN_ARGS=--device=/dev/kvm`; the device must exist and be accessible.
Native execution does not establish activation. Platform `eval`/`run` check the
generic harness and base.

### Build and cache failures

Find the reported derivation and inspect its log in the runner that built it:

```console
nix log /nix/store/DERIVATION.drv
```

Use the real `.drv` path from the diagnostic. A source hash mismatch requires
checking the intended revision and hash; changing a pin merely to obtain a cache
hit can change the product. A missing cache entry for an undeclared dependency
must be resolved before the runtime check can run. Adding an artifact to
`builds` permits only that exact derivation and is not a passing test.
Permissions from dependencies come from default and individual-line public
imports; an import made only inside a test fixture does not extend them.

The PR flow restores one cache per target and architecture with fetcher state
and local builds. A successful job saves a new archive, pruned to the paths that
run needed; only later runs of the same pull request can restore it. A new pull
request starts without a cache and rebuilds what its checks need. The fetcher
archive is best effort and does not guarantee that all source payloads are
available.

Check local logs and configured cache availability before repeating expensive
work. Preserve the failed attempt. A changed cache condition or a fixed fixture
can justify a bounded retry; an unchanged long run provides little new evidence.

### Validation memory

Evaluation memory depends on the module and selected fixtures. Reduce concurrent
evaluators while diagnosing pressure; give the Linux runner the memory rather
than relying on the Mac's total capacity. Confirm an out-of-memory kill in the
kernel log. A skipped historical line or missing VM run is a coverage gap, not a
successful optimization.

When reporting a failed or slow check, include the last completed stage.
[Cost and reports](catalog-contract.md#cost-and-reports) lists the duration
targets and the rest of a report; [Repository automation](automation.md)
describes stage selection.

### Contract and fixture errors

| Error | Correction |
| -- | -- |
| Unknown `test.nix` group or empty `eval` | Export only the public ABI groups and at least one Boolean assertion |
| Read-only user name/home defined more than once | Remove the module assignment; choose the VM identity through `userName`/`userHome` fixture parameters |
| Recursion while resolving imports or options | Keep `pinned` in configuration values; imports and option structure resolve before `_module.args` |
| Capability conflict | Read that schema's identity and merge rule; atomic records need a complete winning declaration |

## Warnings

The catalog emits a warning for version lines marked end of life, for example:

```text
evaluation warning: Docker Engine 28.5.2 no longer receives upstream security updates.
```

This warning is separate from a build error. Use a supported line listed on the
module's page; if the build also fails, investigate its error separately.
