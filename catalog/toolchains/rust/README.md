# Rust

Installs [rustup](https://rust-lang.github.io/rustup/) with the Cargo, rustc,
rustfmt, Clippy, and rust-analyzer commands, plus GCC, pkg-config, and GDB.
rustup downloads the Rust toolchains themselves.

## Select

```toml
[toolchains]
rust = "stable"
```

Set the default toolchain in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). The
client guide describes the
[`[toolchains]` table](https://docs.limanix.dev/config/toolchains).

## Toolchains

The value names the default toolchain of the development account:

| Value | Toolchain |
| -- | -- |
| `stable`, `beta`, `nightly` | The newest release of the channel at install time |
| `nightly-2026-10-01` | A channel as it was on that date |
| `1.90`, `1.90.0` | A Rust release |

A user service installs the toolchain with the rustfmt, Clippy, rust-analyzer,
and `rust-src` components, then makes it the default. It runs when the VM starts
after the value changes, and needs network access to `static.rust-lang.org`.
Until it finishes, Cargo reports that no default toolchain is configured. Follow
it with:

```console
systemctl --user status rust-toolchain
```

A failed download is tried again, after ten seconds at first and then at most
every ten minutes. The toolchain uses the minimal profile. The local
documentation from `rust-docs` is not installed.

rustup keeps toolchains in `~/.rustup` and Cargo keeps downloaded crates in
`~/.cargo`; both stay across VM updates. A channel does not move on its own: run
`rustup update` to fetch its newest release. A default that you set with
`rustup default` stays until the value in `limanix.toml` changes.

## Project toolchains

A project selects its own toolchain with a `rust-toolchain.toml` file, which
rustup installs on first use:

```toml
[toolchain]
channel = "1.89.0"
components = ["rustfmt", "clippy"]
```

See [overrides](https://rust-lang.github.io/rustup/overrides.html) for the order
in which rustup chooses a toolchain.

## Use

Inside the VM, run from a directory that contains `Cargo.toml`:

```console
cargo build
cargo test
cargo fmt
cargo clippy
```

Debug the resulting programs with `rust-gdb`. Commands from `cargo install` go
to `~/.cargo/bin`, which comes first on `PATH`.

## Native dependencies

Crates that bind to system libraries, such as `openssl-sys`, build with the
included GCC and pkg-config. They also need the library's headers and a
pkg-config search path; see
[Handle native dependencies](https://docs.limanix.dev/inside/languages#native-libraries).

## Editor support

The module offers `rust-analyzer` to editors that support the Language Server
Protocol. rustup runs the rust-analyzer of the project's toolchain. The server
matches the compiler. See
[Editor integration](https://docs.limanix.dev/config/toolchains#language-servers-in-the-editor)
and the
[rust-analyzer editor setup](https://rust-analyzer.github.io/book/installation.html).

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public option | `lmx.rust.toolchain`, default `stable`; the client sets it from `[toolchains] rust` |
| Public capability | `lmx.capabilities.languageSupport.tools.rust-analyzer`; Rust parser |
| Personal state | `~/.rustup` toolchains, `~/.cargo` crates and commands, project build output |
| Integration | Declares rust-analyzer without enabling an editor; a user-supplied provider replaces the rustup proxy |
| Services | `rust-toolchain`, a user service of the development account that installs the declared toolchain |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| No network when the VM starts | Cargo has no default toolchain; the service retries, or restart it with `systemctl --user restart rust-toolchain` |
| Project needs another toolchain | Add `rust-toolchain.toml`; rustup installs that toolchain on first use |
| A channel should move | Run `rustup update`; the module installs a toolchain only when the value changes |
| Native dependency fails | GCC and pkg-config are present; provide the required library and its search path |
| Disk fills with toolchains | List them with `rustup toolchain list`, remove one with `rustup toolchain uninstall` |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| rustup, the native build tools, the Rust parser, rust-analyzer and the setup service match the default | `eval.defaults` |
| The value reaches the setup service and the help card | `eval.toolchain` |
| A value that is not a channel or a Rust version fails evaluation | `fails.invalidToolchain` |
| The proxies run a toolchain: Cargo builds and tests offline with GCC, then runs rustfmt and Clippy | `run.commands` |
| The setup installs and selects the declared toolchain once, keeps the user's default, and fails without a marker when the download fails | `run.toolchainSetup` |
| A user-supplied rust-analyzer replaces the proxy in the system profile | `eval.userOverride`, `run.userOverride` |
| Installing this module does not enable an editor | `eval.defaults` |
