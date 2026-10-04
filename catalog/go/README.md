# Go

Installs the Go toolchain, the gopls language server, the Delve debugger, and
GCC for cgo.

```toml
[nixos]
modules = ["lmx:go"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:go` recommends the catalog default. An explicit `lmx:go-LINE` selection
replaces that recommendation, including when Cozy imports the default.

| Selector                | Go      | gopls  | Delve  | Notes       |
| ----------------------- | ------- | ------ | ------ | ----------- |
| `lmx:go`, `lmx:go-1.27` | 1.27.1  | 0.23.0 | 1.27.2 | Default     |
| `lmx:go-1.26`           | 1.26.7  | 0.23.0 | 1.27.2 |             |
| `lmx:go-1.25`           | 1.25.13 | 0.22.0 | 1.26.3 | End of life |
| `lmx:go-1.24`           | 1.24.13 | 0.20.0 | 1.25.2 | End of life |

Support status follows the
[Go release policy](https://go.dev/doc/devel/release). Selecting an end-of-life
line prints a warning when the VM is built. GCC comes from the
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins)
for every line.

## Use

Inside the VM, run from a directory that contains `go.mod`:

```console
go build ./...
go test ./...
```

GCC enables cgo and the race detector:

```console
go test -race ./...
```

Packages that link to C libraries also need those libraries; see
[Handle native dependencies](../../guides/writing-modules.md#handle-native-dependencies).
The Delve debugger runs as `dlv`.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:go-1.26", "lmx:go-1.27"]
```

Each line adds a command with its version, such as `go-1.26`:

```console
go-1.26 test ./...
```

`go`, `gopls`, and `dlv` come from the newest selected line. Only `go` has
versioned commands.

## Toolchain downloads

When a project's `go.mod` or `go.work` requires a newer Go version, Go can
download and run that toolchain instead, including when you run a versioned
command. To use only the installed toolchain, set `GOTOOLCHAIN` in the `[env]`
table of `limanix.toml`:

```toml
[env]
GOTOOLCHAIN = "local"
```

The client guide describes the
[`[env]` table](https://limanix.dev/categories/client/configuration.html#set-the-guest-environment).
With this setting, a project that requires a newer Go version fails to build
instead of downloading a toolchain. See
[Go toolchains](https://go.dev/doc/toolchain#select) for the selection rules.

## Editor support

The module installs `gopls` for editors that support the Language Server
Protocol. See [Editor integration](../../guides/catalog.md#editor-integration)
and the [gopls editor setup](https://go.dev/gopls/#editors).

## Configuration and integration

| Boundary          | Contract                                                                       |
| ----------------- | ------------------------------------------------------------------------------ |
| Public capability | `lmx.capabilities.languageSupport.tools.gopls`; Go, gomod and gosum parsers    |
| Personal state    | Go module and build caches; project `go.mod` and `go.work`                     |
| Integration       | Declares the selected server without enabling an editor; AstroNvim consumes it |
| Services          | No daemon                                                                      |

## Corner cases

| Case                    | Behavior or next step                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------- |
| Another Go version runs | Inspect `PATH` and `GOTOOLCHAIN`; project directives can download a newer toolchain    |
| cgo library is missing  | GCC is included; add the project's required native headers and libraries separately    |
| Several lines selected  | The newest line supplies unqualified Go, gopls and Delve; version suffixes apply to Go |

## Guarantees

| Guarantee                                                                              | Checked by                                                                         |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Go, gopls and Delve versions, parsers and end-of-life warnings match the selected line | `eval.line-1.24`, `eval.line-1.25`, `eval.line-1.26`, `eval.line-1.27`             |
| Explicit lines coexist; ordinary commands and the provider select the newest line      | `eval.allLines`, `run.allLines`                                                    |
| The selected user-supplied provider is installed and runs from the system profile      | `eval.userOverride`, `run.userOverride`                                            |
| Each versioned Go command compiles a cgo package and passes its race-enabled test      | `run.commands-1.24`, `run.commands-1.25`, `run.commands-1.26`, `run.commands-1.27` |
| Installing this module does not enable an editor                                       | `eval.allLines`                                                                    |
