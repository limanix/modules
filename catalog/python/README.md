# Python

Installs the Python interpreter, virtualenv, and the Pyright language server for
project environments inside the VM. The interpreter's separate HTML
documentation is not installed automatically. Runtime `help()` and
standard-library help remain available.

```toml
[nixos]
modules = ["lmx:python"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:python` recommends the catalog default. An explicit `lmx:python-LINE`
selection replaces that recommendation, including when Cozy imports the default.

| Selector | Python | virtualenv | Notes |
| -- | -- | -- | -- |
| `lmx:python`, `lmx:python-3.14` | 3.14.7 | 21.6.1 | Default |
| `lmx:python-3.13` | 3.13.15 | 21.6.1 |  |
| `lmx:python-3.12` | 3.12.14 | 21.6.1 |  |

Upstream support stages and EOL dates are listed in
[Status of Python versions](https://devguide.python.org/versions/).

Each line also adds a command with its version, such as `python-3.14`.

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
> [Handle native dependencies](../../guides/writing-modules.md#handle-native-dependencies).

## Language server

The module installs [Pyright](https://github.com/microsoft/pyright) from the
catalog's base Nixpkgs revision. The language server package follows that
revision independently of the selected Python interpreter line. It declares the
`pyright` tool with `pyright-langserver --stdio` under
`lmx.capabilities.languageSupport`. Selecting
[AstroNvim](../astronvim/README.md) alongside Python enables the declared
server; installing Python alone does not enable an editor. Pyright reads project
settings from `pyrightconfig.json` or `[tool.pyright]` in `pyproject.toml`; see
its
[configuration reference](https://github.com/microsoft/pyright/blob/main/docs/configuration.md).

An ordinary user definition may replace the complete tool declaration, including
its package, command, and arguments. The final declared package is also
installed in the system profile.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

Create an environment for each interpreter with its versioned command:

```console
python-3.12 -m venv .venv-312
python-3.14 -m venv .venv-314
```

Outside an activated environment, `python` and `virtualenv` come from the newest
selected line. An activated environment always uses the interpreter that created
it.

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
| Interpreter and virtualenv versions, the parser and end-of-life warnings match the selected line | `eval.line-3.12`, `eval.line-3.13`, `eval.line-3.14` |
| Installed interpreters retain their identity and priority without implicit HTML documentation | `eval.runtimeOutputSelection` |
| Explicit lines coexist; ordinary commands and the provider select the newest line | `eval.allLines`, `run.allLines` |
| The selected user-supplied provider is installed and runs from the system profile | `eval.userOverride`, `run.userOverride` |
| Each interpreter creates working venv and offline virtualenv environments with pip | `run.commands-3.12`, `run.commands-3.13`, `run.commands-3.14` |
| Installing this module does not enable an editor | `eval.allLines` |
| The declared and user-supplied servers answer an LSP initialization request | `run.languageServer`, `run.userOverride` |
