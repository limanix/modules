---
myst:
  heading_anchors: 2
---

# Native dependencies

Package managers such as pip, npm, and Cargo install a project's libraries.
They do not always provide what those libraries need from the system: a C compiler, system libraries, or the standard Linux program loader.
NixOS keeps all of these under `/nix/store` instead of `/usr` and `/lib`.
Dependencies that expect a conventional Linux layout can fail to build or to start.
A custom module provides what is missing.

## Identify the problem

| What fails | Typical message | Solution |
| --- | --- | --- |
| Building a dependency | `gcc: command not found`, `fatal error: zlib.h: No such file or directory`, or `No package 'openssl' found` | [Build tools and libraries](#build-tools-and-libraries) |
| Starting a downloaded program | `Could not start dynamically linked executable` | [Downloaded programs](#downloaded-programs) |
| Loading a native extension in Python or Node.js | `libstdc++.so.6: cannot open shared object file` | [Native extensions](#native-extensions-in-python-and-nodejs) |

The catalog's language modules cover part of this: Go includes GCC, and Rust includes GCC and pkg-config.
The Python and Node.js modules include no build tools.

## Build tools and libraries

This module installs build tools and makes the headers and pkg-config files of the listed libraries available:

```nix
{ lib, pkgs, ... }:
let
  # System libraries that your dependencies build against.
  libraries = with pkgs; [
    openssl
    zlib
  ];
  developmentPackages = map lib.getDev libraries;
in
{
  environment.systemPackages = [
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
  ]
  ++ developmentPackages;

  environment.variables.PKG_CONFIG_PATH = lib.concatMap (package: [
    "${package}/lib/pkgconfig"
    "${package}/share/pkgconfig"
  ]) developmentPackages;
}
```

Replace `openssl` and `zlib` with the libraries your project needs; the [package search](https://search.nixos.org/packages) lists their attribute names.
Keep only the build tools that your project uses and that your language modules do not already provide.

| Part | Purpose |
| --- | --- |
| `pkgs.gcc` and `pkgs.gnumake` | Compile C and C++ code, for example Python packages built from source or npm packages built with `node-gyp` |
| `pkgs.pkg-config` | Tells build scripts where a library's headers and files are |
| `lib.getDev` | Selects a library's development output, which contains its headers and `.pc` files |
| `PKG_CONFIG_PATH` | Points pkg-config to those `.pc` files |

The Nix toolchain records runtime paths for libraries passed to the linker from `/nix/store`.
Libraries loaded later by a program can still need runtime search paths; see [Native extensions](#native-extensions-in-python-and-nodejs).
For a library without `.pc` files, pass its include and library directories as its build instructions describe.
`node-gyp` also needs Python; select a [Python module](../catalog/python/README.md) as well.

After you [apply the module](#apply-the-module), check inside the VM that pkg-config finds a library:

```console
pkg-config --cflags --libs openssl
```

The command prints compiler and linker flags with paths under `/nix/store`.

## Downloaded programs

Programs built for other Linux distributions expect the program loader at a fixed path under `/lib` or `/lib64`.
Without a compatible loader there, such a program fails with `Could not start dynamically linked executable`.
Tools often download these programs themselves: browsers for test runners, language servers, and prebuilt binaries inside npm and pip packages.

[nix-ld](https://github.com/nix-community/nix-ld) installs a loader at the expected path, together with common libraries:

```nix
{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Libraries that a program needs beyond the default set.
    ];
  };
}
```

The default set includes the C++ runtime, zlib, OpenSSL, and curl, and the `libraries` list adds to it.
nix-ld only helps programs that are built for a glibc-based Linux distribution and for the VM's architecture.

## Native extensions in Python and Node.js

Python and Node.js from Nixpkgs start with their own loader from `/nix/store`, not with nix-ld.
Native extensions that they load, such as the compiled parts of pip and npm packages, therefore cannot find nix-ld's libraries and fail with errors such as `libstdc++.so.6: cannot open shared object file`.

With nix-ld enabled, pass its libraries to the command that fails:

```console
LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" python -c "import numpy"
```

Replace the command with your own, such as `python -m pytest` or `node server.js`.
In a Python virtual environment, activate the environment first.

```{warning}
Set `LD_LIBRARY_PATH` only for the command that needs it.
Setting it for the whole VM can make other programs load incompatible libraries.
```

The [nix-ld documentation](https://github.com/nix-community/nix-ld/blob/2.0.6/README.md#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld) explains why interpreters need this step.

## Apply the module

Save the module in your project, for example as `modules/native-deps/default.nix`, and import it on your Mac:

```console
limanix modules add native-deps ./modules/native-deps
```

Add `third-party:native-deps` to `nixos.modules`, next to your language modules, and [apply the configuration change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).
After later edits, [replace the imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module).
Then open a new shell in the VM and run the command that failed.

## Other approaches

- **Use the package from Nixpkgs.**
  Many tools that download their own binaries are also packaged in Nixpkgs and can be configured to use an installed program.
- **Use Python from Nixpkgs with its packages.**
  [`python3.withPackages`](https://nixos.org/manual/nixpkgs/stable/#python.withPackages) builds an interpreter whose native packages already work on NixOS.
  It is separate from pip virtual environments.
- **Use a container.**
  Run the tool in a container of a Linux distribution that it supports, with the [Docker module](../catalog/docker/README.md).
