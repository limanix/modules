# K9s

Installs K9s, a terminal interface for viewing and managing Kubernetes clusters.

```toml
[nixos]
modules = ["lmx:k9s"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                  | K9s     | Notes   |
|---------------------------|---------|---------|
| `lmx:k9s`, `lmx:k9s-0.51` | 0.51.0  | Default |
| `lmx:k9s-0.50`            | 0.50.18 |         |
| `lmx:k9s-0.40`            | 0.40.10 |         |

Upstream maintenance status for these lines has not been confirmed.
The catalog records their [EOL status](../../guides/catalog.md#versions) as unknown and does not emit an EOL warning for them.

Inside the VM, `k9s version` shows the installed version.

## Use

K9s needs a kubeconfig and access to a running Kubernetes cluster from inside the VM.
With your kubeconfig at `~/.kube/config` inside the VM, start K9s:

```console
k9s
```

To use a kubeconfig at another path, pass its path inside the VM:

```console
k9s --kubeconfig /path/to/kubeconfig
```

See the [K9s usage guide](https://k9scli.io/topics/commands/) for navigation and commands.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:k9s-0.40", "lmx:k9s-0.50", "lmx:k9s-0.51"]
```

Each line adds a command with its version:

```console
k9s-0.40 version
k9s-0.50 version
k9s-0.51 version
```

`k9s` runs the newest selected line.
