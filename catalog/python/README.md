# Python

Installs Python with `venv` and `virtualenv` for isolated project environments inside the VM.

## Enable

Add a Python selector to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:python-3.12"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Python | virtualenv |
|----------|--------|------------|
| `lmx:python` / `lmx:python-3.14` | 3.14.7 | 21.6.1 |
| `lmx:python-3.13` | 3.13.15 | 21.6.1 |
| `lmx:python-3.12` | 3.12.14 | 21.6.1 |

The unversioned selector uses Python 3.14 in this catalog revision.
The example above explicitly selects Python 3.12.

## Use

Inside the VM, create an environment in your project directory and activate it:

```console
virtualenv --python "$(command -v python-3.12)" .venv
source .venv/bin/activate
```

The `command -v` expression passes the installed interpreter's path to `virtualenv`.
Activation makes the environment's `python` available in the current shell.

> [!NOTE]
> A virtual environment does not supply system libraries.
> Building a package from source may require additional build tools and headers.
> Loading a native extension may require runtime libraries even after pip installation succeeds.
> See [Use native dependencies](../../guides/native-dependencies.md) for the available approaches.

If your project has a `requirements.txt`, install its dependencies after activation:

```console
python -m pip install -r requirements.txt
```

Run `deactivate` to leave the environment.
See the [Python virtual environment documentation](https://docs.python.org/3/library/venv.html#how-venvs-work) for activation behavior.

## Use several versions

Select the required versions together:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

After updating the VM from your Mac, create separate environments inside the VM with the versioned interpreters:

```console
virtualenv --python "$(command -v python-3.12)" .venv-312
virtualenv --python "$(command -v python-3.14)" .venv-314
source .venv-312/bin/activate
```

The highest selected version takes priority for the ordinary Python and virtualenv commands before an environment is activated.
An activated environment uses the interpreter selected when that environment was created.
