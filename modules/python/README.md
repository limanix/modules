# Python

Python with venv and virtualenv for isolated project environments.

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

| Selector                         | Python  | virtualenv |
|----------------------------------|---------|------------|
| `lmx:python` / `lmx:python-3.14` | 3.14.7  | 21.6.1     |
| `lmx:python-3.13`                | 3.13.15 | 21.6.1     |
| `lmx:python-3.12`                | 3.12.14 | 21.6.1     |

Create a project environment with a specific interpreter:

```console
virtualenv --python python-3.12 .venv
```
