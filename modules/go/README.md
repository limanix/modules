# Go toolchains

Go compiler, gopls language server, and Delve debugger.

```toml
[nixos]
modules = ["lmx:go-1.24", "lmx:go-1.25"]
```

| Selector                 | Go      | gopls  | Delve  |
|--------------------------|---------|--------|--------|
| `lmx:go` / `lmx:go-1.27` | 1.27.1  | 0.23.0 | 1.27.2 |
| `lmx:go-1.26`            | 1.26.7  | 0.23.0 | 1.27.2 |
| `lmx:go-1.25`            | 1.25.13 | 0.22.0 | 1.26.3 |
| `lmx:go-1.24`            | 1.24.13 | 0.20.0 | 1.25.2 |

Go 1.24 and 1.25 emit an end-of-support warning.

To disable Go's automatic toolchain downloads:

```toml
[env]
GOTOOLCHAIN = "local"
```
