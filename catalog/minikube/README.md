# Minikube

Installs Minikube, which runs local Kubernetes clusters inside the VM.

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube"]
```

Minikube's Docker driver runs clusters in containers.
The example selects the [Docker module](../docker/README.md) to provide Docker, which the Minikube module does not install.
Add the selectors to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                            | Minikube | Notes   |
|-------------------------------------|----------|---------|
| `lmx:minikube`, `lmx:minikube-1.38` | 1.38.1   | Default |
| `lmx:minikube-1.37`                 | 1.37.0   |         |
| `lmx:minikube-1.36`                 | 1.36.0   |         |

## Requirements

[Minikube requires](https://minikube.sigs.k8s.io/docs/start/#what-youll-need) at least 2 CPUs, 2 GB of free memory, and 20 GB of free disk space.
Inside the VM, these come from the `[resources]` table of `limanix.toml`, which also has to cover NixOS, Docker, and your other workloads: `mem = "2GiB"` does not leave 2 GB free.
The client guide describes how to [choose resources](https://limanix.dev/categories/client/configuration.html#choose-resources-and-identity).
The VM also needs internet access to download Kubernetes components and container images.

## Use

The module does not start a cluster.
Inside the VM, create and start one named `dev`, then check its state:

```console
minikube start --driver=docker --profile=dev
minikube status --profile=dev
```

Run kubectl commands through Minikube, which downloads a matching `kubectl` when needed:

```console
minikube kubectl --profile=dev -- get pods -A
```

Options before `--` go to Minikube, and the arguments after it go to kubectl.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube-1.36", "lmx:minikube-1.38"]
```

Each line adds a command with its version, such as `minikube-1.36`.
Give each version its own cluster profile:

```console
minikube-1.36 start --driver=docker --profile=mk136
minikube-1.38 start --driver=docker --profile=mk138
```

`minikube` runs the newest selected line.
