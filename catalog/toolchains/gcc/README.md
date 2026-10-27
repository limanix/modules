# GCC

Installs GCC for C and C++ with GDB, clangd and the common build tools, and lets
compilers find the libraries of `[nixos] packages`.

## Select

```toml
[toolchains]
gcc = "15"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). Add
[Clang](../clang/README.md) in the same table for a second compiler.

## Versions

| Value | GCC | Notes |
| -- | -- | -- |
| `16` | 16.x |  |
| `15` | 15.x | Recommended |
| `14` | 14.x |  |

Lines come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive its updates with each catalog release. `gcc`, `g++`, `cc` and `c++` run
the selected line, also when Go or Rust install their own GCC.

## Use

Inside the VM:

```console
cc -o hello hello.c
c++ -std=c++20 -o hello hello.cpp
```

The module also installs GNU Binutils, `make`, CMake, Ninja, Meson,
`pkg-config`, Autoconf, Automake, Libtool, M4 and GDB:

```console
cmake -B build -G Ninja
cmake --build build
```

## Native libraries

Add a library to `[nixos] packages` and build against it:

```toml
[nixos]
packages = ["openssl", "libpq"]
```

The module installs the development files of `[nixos] packages` and links their
headers, `pkg-config` files, CMake packages and Autoconf macros into the system
profile `/run/current-system/sw`. GCC and Clang search its headers and libraries
after their own, so `cc -o app app.c -lssl` needs no extra flags. Programs they
link search there last for libraries when they run. `pkg-config`, CMake and
`aclocal` find the same packages.

Python packages with C extensions, node-gyp addons and crates with `-sys` build
this way. node-gyp also needs Python: select `python` next to `nodejs` in
`[toolchains]`.

## Editor support

The module installs clangd for C and C++ files in editors that support the
Language Server Protocol; AstroNvim starts it. clangd reads
`compile_commands.json`, which CMake writes with
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, and asks the compiler for its include
paths.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.languageSupport.tools.clangd`; C, C++ and CMake parsers |
| Settings | `environment.extraOutputsToInstall = [ "dev" ]`; links `/include`, `/share/aclocal`, `/share/cmake` and `/share/pkgconfig`; `PKG_CONFIG_PATH`, `CMAKE_PREFIX_PATH` and `ACLOCAL_PATH` point to `/run/current-system/sw` |
| Compilers | `cc`, `c++`, `gcc` and `g++` add `-idirafter /run/current-system/sw/include` and `-L/run/current-system/sw/lib`; dynamic links get `/run/current-system/sw/lib` as their last `RUNPATH` entry |
| Integration | Clang imports this module; Go and Rust keep their GCC behind the selected line |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| A header is missing | Add the library to `[nixos] packages`; its development files come with it |
| A built program misses a library after its package was removed | Add the package back, or rebuild the program |
| CMake does not find a package that keeps its CMake files in another `share` directory, such as Eigen | Use `pkg-config`, or set `<Package>_DIR` |
