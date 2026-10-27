# Clang

Installs Clang with clangd, clang-format, clang-tidy and LLDB next to
[GCC](../gcc/README.md).

## Select

```toml
[toolchains]
clang = "22"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). The
module brings GCC with its build tools and native library support; `cc` and
`c++` stay GCC. Choose the GCC line with `gcc` in the same table.

## Versions

| Value | Clang | Notes |
| -- | -- | -- |
| `22` | 22.x | Recommended |
| `21` | 21.x | End of life |
| `20` | 20.x | End of life |

Lines come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
The LLVM project maintains only its newest release; selecting an older line
prints a warning when the VM is built.

## Use

Inside the VM:

```console
clang++ -std=c++23 -o app main.cpp
CC=clang CXX=clang++ cmake -B build -G Ninja
clang-format -i main.cpp
```

On Linux, Clang uses the C++ standard library and the startup files of GCC. It
finds the headers and libraries of `[nixos] packages` the same way as
[GCC](../gcc/README.md#native-libraries).

## Editor support

The clangd of the selected line replaces the one that comes with GCC. It runs
clang-tidy checks when the project has a `.clang-tidy` file.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.languageSupport.tools.clangd` from the selected line, preferred over the GCC one |
| Integration | Imports GCC; `cc` and `c++` remain GCC |
| Compilers | `clang` and `clang++` search `/run/current-system/sw` like GCC |
| Services | No daemon |
