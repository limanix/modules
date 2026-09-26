# Minikube

Installs Minikube for running local Kubernetes clusters inside the VM.

## Enable

For the Docker driver, add both selectors to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Minikube |
|----------|----------|
| `lmx:minikube` / `lmx:minikube-1.38` | 1.38.1 |
| `lmx:minikube-1.37` | 1.37.0 |
| `lmx:minikube-1.36` | 1.36.0 |

The unversioned selector uses Minikube 1.38 in this catalog revision.

## Use

Check the VM's capacity against [Minikube's requirements](https://minikube.sigs.k8s.io/docs/start/#what-youll-need):

| VM setting | Minikube requirement inside the VM |
| --- | --- |
| `resources.cpu` | At least 2 CPUs |
| `resources.mem` | At least 2 GB of free memory |
| `resources.disk` | At least 20 GB of free disk space |

The `[resources]` table sets the VM's total capacity, including what NixOS, Docker, and other workloads use.
Allocating `mem = "2GiB"` does not guarantee 2 GB free for Minikube.
The `16GiB` disk in the getting-started example is smaller than Minikube's free-space requirement.
Increase insufficient allocations in the existing `[resources]` table on your Mac, then [apply the configuration](../../guides/using-modules.md) before starting the cluster.
The VM also needs internet access to download Kubernetes components and container images.

Start a cluster inside the VM:

```console
minikube start --driver=docker --profile=dev
minikube status --profile=dev
```

The first command creates and starts the `dev` cluster.
The second reports its current state.
The Minikube module installs the command but does not start a cluster or enable Docker.
The example enables Docker separately through the [Docker module](../docker/README.md).

To list pods in all namespaces of the `dev` cluster, run inside the VM:

```console
minikube kubectl --profile=dev -- get pods -A
```

Minikube downloads a matching `kubectl` when needed; a separate installation is not required.
Keep `--profile=dev` before `--`, which separates Minikube's options from the kubectl arguments.

## Use several versions

Select the required versions together:

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube-1.36", "lmx:minikube-1.38"]
```

After updating the VM from your Mac, start separate cluster profiles inside the VM when working with different versions:

```console
minikube-1.36 start --driver=docker --profile=mk136
minikube-1.38 start --driver=docker --profile=mk138
```

The highest selected version supplies the ordinary `minikube` command.
The versioned commands select the Minikube executable; the profile names distinguish the clusters.
