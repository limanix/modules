# Go

Installs the Go toolchain, the gopls language server, the Delve debugger, and
GCC for cgo.

```toml
[toolchains]
go = "1.27"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). The
client guide describes the
[`[toolchains]` table](https://docs.limanix.dev/config/toolchains).

## Versions

The value selects one line:

| Value | Go | gopls | Delve | Notes |
| -- | -- | -- | -- | -- |
| `1.27` | 1.27.x | Base | Base | Recommended |
| `1.26` | 1.26.x | Base | Base |  |
| `1.25` | 1.25.x | Base | Base | End of life |

Lines marked `.x` and their gopls and Delve come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive its updates with each catalog release.

Support status follows the
[Go release policy](https://go.dev/doc/devel/release). Selecting an end-of-life
line prints a warning when the VM is built. GCC comes from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) for
every line.

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
[Handle native dependencies](https://docs.limanix.dev/inside/languages#native-libraries).
The Delve debugger runs as `dlv`.

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
[`[env]` table](https://docs.limanix.dev/config/environment#set-environment-variables).
With this setting, a project that requires a newer Go version fails to build
instead of downloading a toolchain. See
[Go toolchains](https://go.dev/doc/toolchain#select) for the selection rules.

## Editor support

The module installs `gopls` for editors that support the Language Server
Protocol. See
[Editor integration](https://docs.limanix.dev/config/toolchains#language-servers-in-the-editor)
and the [gopls editor setup](https://go.dev/gopls/#editors).

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.languageSupport.tools.gopls`; Go, gomod and gosum parsers |
| Personal state | Go module and build caches; project `go.mod` and `go.work` |
| Integration | Declares the selected server without enabling an editor; AstroNvim consumes it |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Another Go version runs | Inspect `PATH` and `GOTOOLCHAIN`; project directives can download a newer toolchain |
| cgo library is missing | GCC is included; add the project's required native headers and libraries separately |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Go, gopls and Delve versions, parsers and end-of-life warnings match the selected line | `eval.line-1.25`, `eval.line-1.26`, `eval.line-1.27` |
| Explicit lines coexist; ordinary commands and the provider select the newest line | `eval.allLines`, `run.allLines` |
| The selected user-supplied provider is installed and runs from the system profile | `eval.userOverride`, `run.userOverride` |
| Each versioned Go command compiles a cgo package and passes its race-enabled test | `run.commands-1.25`, `run.commands-1.26`, `run.commands-1.27` |
| Installing this module does not enable an editor | `eval.allLines` |
