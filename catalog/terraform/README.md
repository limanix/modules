# Terraform

Installs the Terraform CLI for infrastructure as code.

```toml
[nixos]
modules = ["lmx:terraform"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:terraform` recommends the catalog default. An explicit `lmx:terraform-LINE`
selection replaces that recommendation. Multiple explicit supported lines retain
the side-by-side behavior described below.

| Selector | Terraform | Notes |
| -- | -- | -- |
| `lmx:terraform`, `lmx:terraform-1.16` | 1.16.4 | Default |
| `lmx:terraform-1.15` | 1.15.9 |  |
| `lmx:terraform-1.14` | 1.14.9 |  |

Upstream maintenance status for these Terraform CLI lines has not been
confirmed. The catalog records their
[EOL status](../../guides/catalog.md#versions) as unknown and does not emit an
EOL warning for them.

Terraform uses the
[Business Source License 1.1](https://github.com/hashicorp/terraform/blob/v1.16.4/LICENSE).
The module permits this package in its pinned Nixpkgs import.

## Use

Inside the VM, show the installed Terraform version:

```console
terraform version
```

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:terraform-1.14", "lmx:terraform-1.16"]
```

Each line adds a command with its version:

```console
terraform-1.14 version
terraform-1.16 version
```

`terraform` runs the newest selected line.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Project HCL, backend configuration and native Terraform environment variables |
| Personal state | Project `.terraform/`, provider lock file and the chosen local or remote state backend |
| Integration | Cloud credentials and provider plugins are configured by the project |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Provider is missing | Run `terraform init` for the project; the module installs the CLI, not every provider |
| Wrong account or backend | Inspect the selected credentials, workspace and backend before plan or apply |
| Several versions | Use versioned commands with a state and provider configuration compatible with that line |

## Guarantees

| Guarantee | Covered by |
| -- | -- |
| An explicit version replaces the default recommendation independently of import order | `checks/module.nix`: recommendation |
| Installs the pinned Terraform line and its `terraform-LINE` command | `check.nix`, `smoke.nix`: commands |
| Selected lines coexist and the newest supplies `terraform` | `tests.nix`: coexistence, `smoke.nix`: coexistence |
| Unknown EOL status emits no EOL warning | `check.nix` |
