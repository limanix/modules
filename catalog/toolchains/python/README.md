# Python

Installs the Python interpreter, virtualenv, and the Pyright language server for
project environments inside the VM. Binary wheels from PyPI load as on other
Linux systems. The interpreter's separate HTML documentation is not installed
automatically. Runtime `help()` and standard-library help remain available.

## Select

```toml
[toolchains]
python = "3.15"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). The
client guide describes the
[`[toolchains]` table](https://docs.limanix.dev/config/toolchains).

## Versions

The value selects one line:

| Value | Python | virtualenv | Notes |
| -- | -- | -- | -- |
| `3.15` | 3.15.x | Base | Recommended |
| `3.14` | 3.14.x | Base |  |
| `3.13` | 3.13.x | Base |  |
| `3.12` | 3.12.x | Base |  |

Lines marked `.x` and their virtualenv come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive its updates with each catalog release. The `virtualenv` command creates
environments with the selected Python line.

Upstream support stages and EOL dates are listed in
[Status of Python versions](https://devguide.python.org/versions/).

Each line also adds a command with its version, such as `python-3.15`.

## Use

Inside the VM, create a virtual environment in the project directory, activate
it, and install the project's dependencies:

```console
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

The environment includes pip. `virtualenv .venv` creates an equivalent
environment with the virtualenv tool. Run `deactivate` to leave the environment.

## Binary wheels and native code

Wheels with native code, such as NumPy or pandas, expect the C++ runtime and
zlib that other Linux systems provide. `python` loads both when it starts. The
C++ runtime comes from the newest GCC in Nixpkgs, so it also serves extensions
built with any [GCC](../gcc/README.md) line. Environments created with
`python -m venv` or `virtualenv` run the same interpreter. Programs that Python
starts do not inherit these libraries.

A package that compiles C code while it installs needs a compiler and the
headers of the library it uses: select [GCC](../gcc/README.md) and add the
library to `[nixos] packages`.

## Language server

The module installs [Pyright](https://github.com/microsoft/pyright) from the
catalog's base Nixpkgs revision. The language server package follows that
revision independently of the selected Python interpreter line. It declares the
`pyright` tool with `pyright-langserver --stdio` under
`lmx.capabilities.languageSupport`. Selecting
[AstroNvim](../../shell/astronvim/README.md) alongside Python enables the
declared server; installing Python alone does not enable an editor. Pyright
reads project settings from `pyrightconfig.json` or `[tool.pyright]` in
`pyproject.toml`; see its
[configuration reference](https://github.com/microsoft/pyright/blob/main/docs/configuration.md).

An ordinary user definition may replace the complete tool declaration, including
its package, command, and arguments. The final declared package is also
installed in the system profile.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.languageSupport.tools.pyright`; Python parser |
| Personal state | Project virtual environments, pip cache and Pyright project configuration |
| Runtime libraries | `python3.X` is a copy of the interpreter that loads `libstdc++.so.6` and `libz.so.1` at startup; `python` and `python3` point to it |
| Integration | Declares Pyright independently of interpreter lines without enabling an editor |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Wrong interpreter in a venv | A venv retains the interpreter that created it; recreate it when changing interpreter lines |
| A wheel needs another system library, such as `libGL.so.1` | Add the library to `[nixos] packages` and run Python with `LD_LIBRARY_PATH=/run/current-system/sw/lib` |
| HTML manuals are absent | Runtime `help()` remains available; select an HTML documentation package separately if needed |
| Pyright cannot find project dependencies | Configure the project environment in `pyrightconfig.json` or `pyproject.toml` |
