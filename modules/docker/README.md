# Docker

System Docker Engine and the Compose plugin. 
The VM user joins the `docker` group, which grants root-equivalent access inside the guest.

```toml
[nixos]
modules = ["lmx:docker-28"]
```

| Selector                       | Engine / CLI | Compose |
|--------------------------------|--------------|---------|
| `lmx:docker` / `lmx:docker-29` | 29.8.0       | 5.5.1   |
| `lmx:docker-28`                | 28.5.2       | 5.1.3   |

Select one Docker version per VM. Use `docker` and `docker compose` as usual.
Changing the version does not create separate container or volume storage.

Docker 28 emits an end-of-support warning.
