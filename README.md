[![Release](https://img.shields.io/github/v/release/limanix/modules)](https://github.com/limanix/modules/releases)
[![License: Apache-2.0](https://img.shields.io/github/license/limanix/modules?label=license)](LICENSE)

<div align="center">
<img src=".github/assets/readme-header.png" alt="LimaNix" width="100%">

<p align="center">
<a href="https://docs.limanix.dev/quick-start"><code>→ Get started</code></a>
<a href="https://docs.limanix.dev/"><code>Documentation</code></a>
<a href="https://docs.limanix.dev/contributing/"><code>Contributing</code></a>
</p>

<p align="center"><sub>macOS 26 or newer | Apple Silicon and Intel</sub></p>
</div>

## Catalog and VM images

The NixOS catalog and base disk images for [LimaNix](https://limanix.dev).
Choose shell components, language toolchains and services through
`limanix.toml`.

- **Build your shell.** Combine Zsh, tmux, editors and command-line tools with
  the catalog's prompts and themes.
- **Choose language tools.** Use Go, Python, Node.js, Rust, Java and native
  compilers, with version lines for toolchains that support them.
- **Add services and tools.** Enable Docker, PostgreSQL, Google Cloud CLI and
  other catalog modules.
- **Boot a NixOS VM.** Each release provides base disk images for Apple Silicon
  and Intel Macs.

Explore the [interactive catalog](https://limanix.dev/catalog) and read the
[module guides](https://docs.limanix.dev/modules/).

## Development

> Requires [Task](https://taskfile.dev) 3.53.1+ and Docker.

Check a module with `task ci/catalog/modules MODULES=go`; use `task -l` to list
checks and build commands.

Check Markdown with `task ci/markdown/fmt`; format it with
`task markdown/fmt/fix`.

## Contributing

See the [contribution guide](https://docs.limanix.dev/contributing/) for issues,
pull requests and releases, and the [catalog contract](catalog/README.md) for
module structure, interfaces and checks.
