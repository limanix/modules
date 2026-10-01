# Python

Installs the Python interpreter and virtualenv for project environments inside the VM.

```toml
[nixos]
modules = ["lmx:python"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                        | Python  | virtualenv | Notes   |
|---------------------------------|---------|------------|---------|
| `lmx:python`, `lmx:python-3.14` | 3.14.7  | 21.6.1     | Default |
| `lmx:python-3.13`               | 3.13.15 | 21.6.1     |         |
| `lmx:python-3.12`               | 3.12.14 | 21.6.1     |         |

Upstream support stages and EOL dates are listed in [Status of Python versions](https://devguide.python.org/versions/).

Each line also adds a command with its version, such as `python-3.14`.

## Use

Inside the VM, create a virtual environment in the project directory, activate it, and install the project's dependencies:

```console
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

The environment includes pip.
`virtualenv .venv` creates an equivalent environment with the virtualenv tool.
Run `deactivate` to leave the environment.

> [!NOTE]
> A virtual environment does not provide system libraries.
> A pip package that compiles C code or loads a native extension can need build tools or libraries even after it installs; see [Handle native dependencies](../../guides/writing-modules.md#handle-native-dependencies).

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

Outside an activated environment, `python` and `virtualenv` come from the newest selected line.
An activated environment always uses the interpreter that created it.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the selected Python interpreter and virtualenv; `python-LINE` selects that interpreter | `check.nix`, `smoke.nix`: commands |
| Both venv and virtualenv create isolated environments with pip | `smoke.nix`: commands |
| Selected lines coexist and the newest supplies ordinary commands outside an activated environment | `tests.nix`: coexistence, `smoke.nix`: coexistence |
| Declares Python parser support without installing an LSP server or enabling an editor | `check.nix`, `tests.nix` |
