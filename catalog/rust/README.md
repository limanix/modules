# Rust

Installs the Rust toolchain (rustc, Cargo, rustfmt, and Clippy) with the rust-analyzer language server, GCC, pkg-config, and GDB.

```toml
[nixos]
modules = ["lmx:rust"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).

## Versions

| Selector                    | Rust   | rust-analyzer | Notes       |
|-----------------------------|--------|---------------|-------------|
| `lmx:rust`, `lmx:rust-1.98` | 1.98.1 | 2026-08-03    | Default     |
| `lmx:rust-1.97`             | 1.97.1 | 2026-08-03    | End of life |
| `lmx:rust-1.96`             | 1.96.1 | 2026-06-15    | End of life |
| `lmx:rust-1.95`             | 1.95.0 | 2026-04-27    | End of life |

rustc, Cargo, rustfmt, and Clippy come from the same Rust release.
GCC, pkg-config, and GDB come from the [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins) for every line.
Selecting an end-of-life line prints a warning when the VM is built.

## Use

Inside the VM, run from a directory that contains `Cargo.toml`:

```console
cargo build
cargo test
cargo fmt
cargo clippy
```

Debug the resulting programs with `gdb`.

## Native dependencies

Crates that bind to system libraries, such as `openssl-sys`, build with the included GCC and pkg-config.
They also need the library's headers and a pkg-config search path; see [Handle native dependencies](../../guides/writing-modules.md#handle-native-dependencies).

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:rust-1.95", "lmx:rust-1.98"]
```

Each line adds versioned commands: `cargo-1.95`, `rustc-1.95`, `rustdoc-1.95`, `rustfmt-1.95`, and `rust-analyzer-1.95` for Rust 1.95.

```console
cargo-1.95 build
cargo-1.95 clippy
```

`cargo-1.95` puts the whole Rust 1.95 toolchain first on `PATH`.
Its subcommands and build scripts use that version, including `cargo fmt` and `cargo clippy`.
Commands without a version come from the newest selected line.

## Editor support

The module installs `rust-analyzer` for editors that support the Language Server Protocol.
See [Editor integration](../../guides/catalog.md#editor-integration) and the [rust-analyzer editor setup](https://rust-analyzer.github.io/book/installation.html).
