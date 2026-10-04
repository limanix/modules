# Minikube

Installs Minikube, which runs local Kubernetes clusters inside the VM, and K9s
for browsing them from the terminal.

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube"]
```

Minikube's Docker driver runs clusters in containers. The example selects the
[Docker module](../docker/README.md) to provide Docker, which the Minikube
module does not install. Add the selectors to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:minikube` recommends the catalog default. An explicit `lmx:minikube-LINE`
selection replaces that recommendation, including when Cozy imports the default.

| Selector                            | Minikube | Notes   |
| ----------------------------------- | -------- | ------- |
| `lmx:minikube`, `lmx:minikube-1.38` | 1.38.1   | Default |
| `lmx:minikube-1.37`                 | 1.37.0   |         |
| `lmx:minikube-1.36`                 | 1.36.0   |         |

Upstream maintenance status for these Minikube lines has not been confirmed. The
catalog records their [EOL status](../../guides/catalog.md#versions) as unknown
and does not emit an EOL warning for them.

## Requirements

[Minikube requires](https://minikube.sigs.k8s.io/docs/start/#what-youll-need) at
least 2 CPUs, 2 GB of free memory, and 20 GB of free disk space. Inside the VM,
these come from the `[resources]` table of `limanix.toml`, which also has to
cover NixOS, Docker, and your other workloads: `mem = "2GiB"` does not leave 2
GB free. The client guide describes how to
[choose resources](https://limanix.dev/categories/client/configuration.html#choose-resources-and-identity).
The VM also needs internet access to download Kubernetes components and
container images.

## Use

The module does not start a cluster. Inside the VM, create and start one named
`dev`, then check its state:

```console
minikube start --driver=docker --profile=dev
minikube status --profile=dev
```

Run kubectl commands through Minikube, which downloads a matching `kubectl` when
needed:

```console
minikube kubectl --profile=dev -- get pods -A
```

Options before `--` go to Minikube, and the arguments after it go to kubectl.

### K9s

After starting the cluster, open its terminal interface:

```console
k9s --context dev
```

The module includes the [K9s catalog default](../k9s/README.md#versions) as the
`k9s` command when no K9s version is selected explicitly. Select
`lmx:k9s-VERSION` as well to replace that default and add its version-suffixed
command. For example, `lmx:k9s-0.40` installs that line instead of the catalog
default. If several K9s versions are selected explicitly, `k9s` runs the newest
selected line.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube-1.36", "lmx:minikube-1.38"]
```

Each line adds a command with its version, such as `minikube-1.36`. Give each
version its own cluster profile:

```console
minikube-1.36 start --driver=docker --profile=mk136
minikube-1.38 start --driver=docker --profile=mk138
```

`minikube` runs the newest selected line.

## Configuration and integration

| Boundary       | Contract                                                                   |
| -------------- | -------------------------------------------------------------------------- |
| Settings       | Native Minikube profiles and configuration                                 |
| Personal state | `~/.minikube/`, kubeconfig and the selected driver's cluster storage       |
| Integration    | Recommends K9s; Docker remains a separate component or is supplied by Cozy |
| Services       | No cluster starts from selecting this module                               |

## Corner cases

| Case                              | Behavior or next step                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------ |
| Docker driver cannot start        | Check Docker Engine, account access and available guest CPU, memory and disk         |
| Cluster components need downloads | The installed command is not a pre-created cluster; first start needs network access |
| Several Minikube lines            | Give each version its own profile and check the active Kubernetes context            |

## Guarantees

| Guarantee                                                                                                  | Checked by                                                                                                          |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Each Minikube line installs its package with the expected warning behavior and a working versioned command | `eval.line-1.36`, `eval.line-1.37`, `eval.line-1.38`, `run.commands-1.36`, `run.commands-1.37`, `run.commands-1.38` |
| Selected lines coexist; the newest package supplies `minikube`                                             | `eval.allLines`, `run.allLines`                                                                                     |
| An explicit K9s line preserves the selected Minikube line                                                  | `eval.explicitDependency`                                                                                           |
| The default dependency supplies a working K9s command                                                      | `run.dependency`                                                                                                    |
| Selection adds no boot units or activation commands and leaves Docker disabled                             | `eval.noStartup`, `eval.optionalDocker`                                                                             |

`eval.noStartup` compares units, enabled flags and activation commands with the
empty platform. It normalizes only the generated `/etc` path and D-Bus restart
reference changed by installing packages. These checks do not start a cluster.
