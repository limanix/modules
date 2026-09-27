# Docker

Runs Docker Engine as a system service in the VM, with the Docker CLI and the Compose plugin.

```toml
[nixos]
modules = ["lmx:docker"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).

## Versions

| Selector                      | Docker Engine and CLI | Notes       |
|-------------------------------|-----------------------|-------------|
| `lmx:docker`, `lmx:docker-29` | 29.8.0                | Default     |
| `lmx:docker-28`               | 28.5.2                | End of life |

Selecting an end-of-life line prints a warning when the VM is built.

Select only one line per VM.
Both lines configure the same Docker service.
Selecting two of them stops the build with this error:

```text
The option `virtualisation.docker.package' is defined multiple times while it's expected to be unique.
```

Both lines keep their containers, images, and volumes in the same storage in the VM; switching lines does not create a separate Docker environment.

## Use

Inside the VM, check that Docker Engine runs:

```console
docker ps
```

The command lists running containers; an empty list is normal before you start any.

To run a Compose project from your Mac, first [share its directory with the VM](https://limanix.dev/categories/client/configuration.html#share-project-directories).
Then run this inside the VM, from the directory that contains the Compose file:

```console
docker compose up -d
```

## Permissions

The module adds the VM's user to the `docker` group to allow Docker commands without `sudo`.

> [!WARNING]
> Membership in the `docker` group is equivalent to root access in the VM.

## Published ports

`docker run -p 8080:80 IMAGE` publishes the container's port 80 on port 8080 of the VM.
To connect from your Mac, use the VM's address and the published port; [Reach services in the VM](https://limanix.dev/categories/client/networking.html) shows how to find the address.

Docker manages the firewall rules for published ports itself:

- A published port is reachable without adding it to `network.ports` in `limanix.toml`.
- Removing a port from `network.ports` does not close a published port.
- To keep a port inside the VM, publish it on the loopback address, such as `-p 127.0.0.1:8080:80`.

Compose `ports:` entries behave the same way.
A container started with `--network host` uses the VM's network directly.
`network.ports` applies to it as to any other service in the VM.
For details, see Docker's guides to [port publishing](https://docs.docker.com/engine/network/port-publishing/) and [firewall rules](https://docs.docker.com/engine/network/firewall-iptables/).
