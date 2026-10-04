# Lazydocker

Installs Lazydocker, a terminal interface for Docker containers, images, and
Compose projects.

```toml
[nixos]
modules = ["lmx:lazydocker"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Lazydocker comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `lazydocker --version` shows
the installed version.

## Use

Lazydocker needs the Docker CLI and access to a running Docker Engine. The
[Docker module](../docker/README.md) provides both and already includes
Lazydocker. Select `lmx:docker` for the local engine and interface together. The
separate `lmx:lazydocker` selector installs only the interface for an existing
Docker setup.

Inside the VM, run:

```console
lazydocker
```

The interface shows containers and their logs, images, and volumes.

## Configuration and integration

| Boundary                  | Contract                                                                       |
| ------------------------- | ------------------------------------------------------------------------------ |
| Settings                  | Personal Lazydocker configuration, normally `~/.config/lazydocker/config.yml`  |
| Integration               | Docker Engine and CLI are supplied by Docker or another configured environment |
| Services and capabilities | No daemon or language-support declarations                                     |

## Corner cases

| Case                     | Behavior or next step                                              |
| ------------------------ | ------------------------------------------------------------------ |
| Cannot connect to Docker | Check `docker ps`, the daemon and socket permissions in the guest  |
| Standalone selection     | Installing the interface does not start or install a Docker Engine |
| Read-write mounts        | Container operations may affect volumes and mounted project files  |

## Guarantees

| Guarantee                                                                | Checked by      |
| ------------------------------------------------------------------------ | --------------- |
| Installs the base Nixpkgs Lazydocker package                             | `eval.package`  |
| Standalone selection leaves Docker Engine disabled                       | `eval.noDocker` |
| The system-profile command prints its version and help without an engine | `run.commands`  |
