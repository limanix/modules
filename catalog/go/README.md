# Go

Installs the Go compiler, the gopls language server, the Delve debugger, and GCC inside the VM.

## Enable

Add a Go selector to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:go"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Go | gopls | Delve |
|----------|----|-------|-------|
| `lmx:go` / `lmx:go-1.27` | 1.27.1 | 0.23.0 | 1.27.2 |
| `lmx:go-1.26` | 1.26.7 | 0.23.0 | 1.27.2 |
| `lmx:go-1.25` | 1.25.13 | 0.22.0 | 1.26.3 |
| `lmx:go-1.24` | 1.24.13 | 0.20.0 | 1.25.2 |

The unversioned selector uses Go 1.27 in this catalog revision.
The catalog marks Go 1.24 and 1.25 as end of life and emits a warning when either is selected.

## Use

Inside the VM, run these commands from a Go project containing `go.mod`:

```console
go build ./...
go test ./...
```

`go build ./...` compiles the project's packages and reports build errors.
`go test ./...` runs their tests and reports the results for each package.
The debugger is available as `dlv`.

GCC is included for cgo and the race detector:

```console
go test -race ./...
```

Projects that link to external C libraries need those libraries and their headers separately.

## Editor support

The module installs the `gopls` language server inside the VM.
See [Use language servers](../../guides/using-modules.md#use-language-servers) for connecting your editor and the [gopls editor setup](https://go.dev/gopls/#editors) for configuration.

## Use several versions

Select the required versions together:

```toml
[nixos]
modules = ["lmx:go-1.26", "lmx:go-1.27"]
```

After updating the VM from your Mac, use the versioned command inside the VM to choose an installed Go distribution:

```console
go-1.26 test ./...
go-1.27 test ./...
```

The highest selected Go version takes priority for the ordinary `go`, `gopls`, and `dlv` commands.
Only `go` receives a versioned command; the module does not add names such as `gopls-1.26` or `dlv-1.26`.

## Toolchain downloads

Go can select or download another toolchain according to `GOTOOLCHAIN`, `go.mod`, and `go.work`, including when started through a versioned command.
To use only the toolchain bundled with the selected `go` command, set `GOTOOLCHAIN` in the VM configuration:

```toml
[env]
GOTOOLCHAIN = "local"
```

Add the key to an existing `[env]` table if you already have one.
If the configuration contains the top-level `env = {}` line, remove it before adding the table.
Apply the configuration as described in [Use catalog modules](../../guides/using-modules.md).

With `GOTOOLCHAIN = "local"`, a project requiring a newer Go version fails instead of switching toolchains.
See [Go toolchain selection](https://go.dev/doc/toolchain#select) for the selection rules.
