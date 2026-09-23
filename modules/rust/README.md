# Rust toolchains

Rust compiler, Cargo, rustfmt, Clippy, rust-analyzer, GCC, pkg-config, and GDB.

```toml
[nixos]
modules = ["lmx:rust-1.95", "lmx:rust-1.98"]
```

| Selector                     | Rust   | rust-analyzer |
|------------------------------|--------|---------------|
| `lmx:rust` / `lmx:rust-1.98` | 1.98.1 | 2026-08-03    |
| `lmx:rust-1.97`              | 1.97.1 | 2026-08-03    |
| `lmx:rust-1.96`              | 1.96.1 | 2026-06-15    |
| `lmx:rust-1.95`              | 1.95.0 | 2026-04-27    |

Use the matching compiler, formatter, and linter through Cargo:

```console
cargo-1.95 build
cargo-1.95 fmt
cargo-1.95 clippy
```

Rust 1.95–1.97 emit an end-of-support warning.
