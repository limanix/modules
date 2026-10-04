# K9s

Installs K9s, a terminal interface for viewing and managing Kubernetes clusters.

```toml
[nixos]
modules = ["lmx:k9s"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                  | K9s     | Notes   |
| ------------------------- | ------- | ------- |
| `lmx:k9s`, `lmx:k9s-0.51` | 0.51.0  | Default |
| `lmx:k9s-0.50`            | 0.50.18 |         |
| `lmx:k9s-0.40`            | 0.40.10 |         |

Upstream maintenance status for these lines has not been confirmed. The catalog
records their [EOL status](../../guides/catalog.md#versions) as unknown and does
not emit an EOL warning for them.

The 0.40 line retains its pinned K9s application and vendor sources while using
a separately pinned Go build toolchain. That compiler belongs to the package
recipe and is independent of the [Go SDK](../go/README.md) selected for your
project. The default remains 0.51.

Inside the VM, `k9s version` shows the installed version.

## Use

K9s needs a kubeconfig and access to a running Kubernetes cluster from inside
the VM. With your kubeconfig at `~/.kube/config` inside the VM, start K9s:

```console
k9s
```

To use a kubeconfig at another path, pass its path inside the VM:

```console
k9s --kubeconfig /path/to/kubeconfig
```

See the [K9s usage guide](https://k9scli.io/topics/commands/) for navigation and
commands.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:k9s-0.40", "lmx:k9s-0.50", "lmx:k9s-0.51"]
```

Each selected version line adds a command with its version, including the
default:

```console
k9s-0.40 version
k9s-0.50 version
k9s-0.51 version
```

`k9s` runs the newest selected line. Both `lmx:k9s` and
[Minikube](../minikube/README.md#k9s) recommend the catalog default through the
same entry point. An explicit `lmx:k9s-VERSION` replaces that recommendation.
For example, `lmx:k9s` together with `lmx:k9s-0.40` installs only 0.40. Select
`lmx:k9s-0.40` and `lmx:k9s-0.51` explicitly to install both. The default and
explicit entry points provide the same commands for the same line, including
`k9s-LINE`.

## Configuration and integration

| Boundary                  | Contract                                                                                     |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| Settings                  | Native K9s configuration, normally under `~/.config/k9s/`                                    |
| Personal state            | Kubeconfig and K9s configuration in the guest home                                           |
| Integration               | Included as a default recommendation by Minikube; explicit lines replace that recommendation |
| Services and capabilities | No cluster, daemon or language-support declarations                                          |

## Corner cases

| Case                              | Behavior or next step                                                                                  |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| No cluster or authentication      | Provide a guest-readable kubeconfig and reachable cluster                                              |
| Historical 0.40 build             | Application sources stay pinned; its separately pinned build compiler does not select a project Go SDK |
| Wrong context                     | Pass `--context` or inspect the active kubeconfig context before changes                               |
| Default versus explicit selection | Both entry points provide the same ordinary and version-suffixed commands                              |

## Local builds

`builds.k9s-0.40` and `builds.k9s-upstream-version-0.40` permit the exact
historical package and upstream version-test derivations. They are build
permissions; `run.upstreamVersion` executes the version test. Uncached
dependencies still need a cache.

## Guarantees

| Guarantee                                                                                   | Checked by                                                    |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Each K9s line installs its package and emits applicable warnings once                       | `eval.line-0.40`, `eval.line-0.50`, `eval.line-0.51`          |
| Selected lines coexist; the newest package supplies `k9s`                                   | `eval.allLines`, `run.allLines`                               |
| Each line provides working ordinary and version-suffixed commands                           | `run.commands-0.40`, `run.commands-0.50`, `run.commands-0.51` |
| The rebuilt historical line keeps its application, vendor sources and declared compiler pin | `eval.buildSource`                                            |
| The rebuild retains upstream checks and matching build paths                                | `eval.checkCache`                                             |
| The upstream version test executes the rebuilt package                                      | `eval.rebuiltVersionTest`, `run.upstreamVersion`              |

These checks do not connect to a cluster or establish guest authentication.
