# Python

Installs the Python interpreter, virtualenv, and the Pyright language server for
project environments inside the VM. The interpreter's separate HTML
documentation is not installed automatically. Runtime `help()` and
standard-library help remain available.

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

> [!NOTE]
>
> A virtual environment does not provide system libraries. A pip package that
> compiles C code or loads a native extension can need build tools or libraries
> even after it installs; see
> [Handle native dependencies](https://docs.limanix.dev/inside/languages#native-libraries).

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
| Integration | Declares Pyright independently of interpreter lines without enabling an editor |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Wrong interpreter in a venv | A venv retains the interpreter that created it; recreate it when changing interpreter lines |
| Native extension fails | A venv does not supply compilers or system libraries |
| HTML manuals are absent | Runtime `help()` remains available; select an HTML documentation package separately if needed |
| Pyright cannot find project dependencies | Configure the project environment in `pyrightconfig.json` or `pyproject.toml` |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Each selected line installs its interpreter and language server, offers the parser and reports end-of-life warnings | `eval.line-3.12`, `eval.line-3.13`, `eval.line-3.14`, `eval.line-3.15` |
| Installed interpreters retain their identity and priority without implicit HTML documentation | `eval.runtimeOutputSelection` |
| Explicit lines coexist; ordinary commands and the provider select the newest line | `eval.allLines`, `run.allLines` |
| The selected user-supplied provider is installed and runs from the system profile | `eval.userOverride`, `run.userOverride` |
| Each interpreter creates working venv and offline virtualenv environments with pip | `run.commands-3.12`, `run.commands-3.13`, `run.commands-3.14`, `run.commands-3.15` |
| The declared and user-supplied servers answer an LSP initialization request | `run.languageServer`, `run.userOverride` |
