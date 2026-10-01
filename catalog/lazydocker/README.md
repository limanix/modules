# Lazydocker

Installs Lazydocker, a terminal interface for Docker containers, images, and Compose projects.

```toml
[nixos]
modules = ["lmx:lazydocker"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Lazydocker comes from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.
Inside the VM, `lazydocker --version` shows the installed version.

## Use

Lazydocker needs the Docker CLI and access to a running Docker Engine.
The [Docker module](../docker/README.md) provides both and already includes Lazydocker, so selecting `lmx:docker` is enough for a local engine.
The separate `lmx:lazydocker` selector installs only the interface for an existing Docker setup.

Inside the VM, run:

```console
lazydocker
```

The interface shows containers and their logs, images, and volumes.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the base Nixpkgs package providing `lazydocker` | `check.nix` |
| Selecting Lazydocker alone does not enable Docker Engine | `tests.nix` |
