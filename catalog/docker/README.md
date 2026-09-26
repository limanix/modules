# Docker

Installs Docker Engine, its command-line client, and the Compose plugin inside the VM.

## Enable

Add a Docker selector to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:docker"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Engine / CLI |
|----------|--------------|
| `lmx:docker` / `lmx:docker-29` | 29.8.0 |
| `lmx:docker-28` | 28.5.2 |

The unversioned selector uses Docker 29 in this catalog revision.
The catalog marks Docker 28 as end of life and emits a warning when it is selected.

## Use

Run Docker commands inside the VM:

```console
docker ps
```

This lists running containers.
An empty list is normal before you start any containers.

If your Compose project is on your Mac, [Share a project directory](../../guides/using-modules.md#share-a-project-directory) first.
Inside the VM, change to the project directory containing the Compose file, then start its services:

```console
docker compose up -d
```

The module enables the system Docker service and adds the configured VM user to the `docker` group.

> [!WARNING]
> Membership in the `docker` group grants root-equivalent access inside the VM.

Select one Docker version per VM.
Selecting Docker 28 and 29 together causes an evaluation error for `virtualisation.docker.package` during create or update.
The selectors configure the same system daemon and storage; changing the version does not create separate containers or volumes.

## Reach a container from your Mac

With Docker's default bridge network, `-p 8080:80` maps TCP port `8080` on the **VM** to port `80` in the container.
Inside the VM, run the following command, replacing `IMAGE` with an image whose application listens on `0.0.0.0:80`:

```console
docker run --rm -p 8080:80 IMAGE
```

In another terminal on your **Mac**, run `limanix list` and read the VM's `ADDRESS`.
For an HTTP application, open `http://<ADDRESS>:8080` in your browser.
Limanix does not forward this port to `localhost:8080` on your Mac.

| Publication | Access |
| --- | --- |
| `-p 8080:80` | Port `8080` on the VM's network addresses |
| `-p 127.0.0.1:8080:80` | Published on the VM's loopback address, unavailable through its network IP from your Mac |
| No `-p` | No port mapping on the VM's addresses |

Compose's `ports: ["8080:80"]` publishes the same mapping.

### How `network.ports` applies

In the standard Docker module configuration, you do not need to add `8080` to `network.ports.tcp` for this bridge-network publication.
Docker creates its own forwarding rules; incoming traffic to the published port follows NAT and `FORWARD`, bypassing the guest firewall's `INPUT` port rules.
Those `INPUT` rules are what Limanix configures through `network.ports`.

> [!WARNING]
> Removing a port from `network.ports` does not close a Docker-published bridge port.
> `-p 8080:80` publishes on all VM addresses by default, allowing connections from any host that can reach them.
> Publish only the ports you need, or bind to `127.0.0.1` when access through the VM's loopback address is sufficient.

With `--network host`, the application uses the VM's network directly, `-p` is ignored, and the normal guest firewall rules apply.
Custom Docker network or firewall settings can change the behavior described above.
See Docker's [port publishing](https://docs.docker.com/engine/network/port-publishing/) and [firewall rules](https://docs.docker.com/engine/network/firewall-iptables/) for details and source-address filtering.
