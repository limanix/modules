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
| `lmx:helm-4.2`             | 4.2.4  | End of life |
| `lmx:helm-3.20`            | 3.20.2 | End of life |

The catalog derives these EOL marks from Helm's [version support policy](https://helm.sh/docs/topics/version_skew/#supported-versions), also documented for [Helm 3](https://helm.sh/docs/v3/topics/version_skew/#supported-versions).
As of September 30, 2026, the maintained minor lines are 3.22 and 4.3.
Selecting an end-of-life line prints a warning when the VM is built.

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

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the pinned Helm line and its `helm-LINE` command | `check.nix`, `smoke.nix`: commands |
| Selected lines coexist and the newest supplies `helm` | `tests.nix`: coexistence, `smoke.nix`: coexistence |
| Selecting a line recorded as end-of-life emits its version-specific warning | `check.nix` |
