# Helm

Installs Helm, a package manager for Kubernetes.

```toml
[nixos]
modules = ["lmx:helm"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                   | Helm   | Notes   |
|----------------------------|--------|---------|
| `lmx:helm`, `lmx:helm-4.3` | 4.3.0  | Default |
| `lmx:helm-4.2`             | 4.2.4  |         |
| `lmx:helm-3.20`            | 3.20.2 |         |

Inside the VM, `helm version --short` shows the installed version.

## Use

To manage releases in a cluster, Helm needs a kubeconfig and access to that Kubernetes cluster from inside the VM.
List releases across namespaces, passing the kubeconfig's path inside the VM:

```console
helm list --all-namespaces --kubeconfig /path/to/kubeconfig
```

See the [Helm command reference](https://helm.sh/docs/helm/) for chart and release commands.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:helm-3.20", "lmx:helm-4.2", "lmx:helm-4.3"]
```

Each line adds a command with its version:

```console
helm-3.20 version --short
helm-4.2 version --short
helm-4.3 version --short
```

`helm` runs the newest selected line.
