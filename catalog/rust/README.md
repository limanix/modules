# Rust

Installs rustc, Cargo, rustfmt, Clippy, rust-analyzer, GCC, pkg-config, and GDB inside the VM.

## Enable

Add a Rust selector to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:rust"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Rust toolchain | rust-analyzer |
|----------|----------------|---------------|
| `lmx:rust` / `lmx:rust-1.98` | 1.98.1 | 2026-08-03 |
| `lmx:rust-1.97` | 1.97.1 | 2026-08-03 |
| `lmx:rust-1.96` | 1.96.1 | 2026-06-15 |
| `lmx:rust-1.95` | 1.95.0 | 2026-04-27 |

The unversioned selector uses Rust 1.98 in this catalog revision.
The toolchain includes rustc, Cargo, rustfmt, and Clippy from the same Rust package set.
GCC, pkg-config, and GDB come from the VM's base Nixpkgs.
The catalog marks Rust 1.95–1.97 as end of life and emits a warning when one of those versions is selected.

## Use

Inside the VM, run these commands from a Rust project containing `Cargo.toml`:

```console
cargo build
cargo test
cargo fmt
cargo clippy
```

| Command | Result |
| --- | --- |
| `cargo build` | Compiles the project and its dependencies |
| `cargo test` | Runs tests and reports their results |
| `cargo fmt` | Formats the project's Rust source files |
| `cargo clippy` | Reports common mistakes and code improvement suggestions |

## Editor support

The module installs the `rust-analyzer` language server inside the VM.
See [Use language servers](../../guides/using-modules.md#use-language-servers) for connecting your editor and the [rust-analyzer editor setup](https://rust-analyzer.github.io/book/installation.html) for configuration.

## Native dependencies

This module includes GCC and pkg-config for building code that uses system libraries.
Your project may also need library headers and pkg-config search paths.
See [Use native dependencies](../../guides/native-dependencies.md) to configure them.

## Use several versions

Select the required versions together:

```toml
[nixos]
modules = ["lmx:rust-1.95", "lmx:rust-1.98"]
```

After updating the VM from your Mac, use the versioned Cargo wrapper inside the VM for the corresponding toolchain:

```console
cargo-1.95 build
cargo-1.95 fmt
cargo-1.95 clippy
```

The wrapper places its selected rustc, Cargo, rustfmt, Clippy, and rust-analyzer packages at the front of `PATH`.
This selects the matching compiler and Cargo subcommands unless the project or environment explicitly overrides them.

Each selection also provides versioned `rustc`, `rustdoc`, `rustfmt`, and `rust-analyzer` commands, such as `rustc-1.95` and `rust-analyzer-1.95`.
The versioned rust-analyzer wrapper uses the same toolchain on `PATH`.
The highest selected version takes priority for the ordinary toolchain commands.
