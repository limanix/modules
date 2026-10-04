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
The module declares `nixpkgs.config.allowUnfreePackages = [ "terraform" ]`. This
permission applies to the evaluated system and its declared pins. It does not
grant permission to unrelated unfree packages.

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

## Local builds

The module declares exact build permissions for each CLI and its vendor inputs:

| Line | CLI | Vendor inputs |
| -- | -- | -- |
| 1.14 | `builds.terraform-1.14` | `builds.terraform-vendor-1.14` |
| 1.15 | `builds.terraform-1.15` | `builds.terraform-vendor-1.15` |
| 1.16 | `builds.terraform-1.16` | `builds.terraform-vendor-1.16` |

These permissions do not execute tests or cover dependencies. An uncached
compiler or another dependency fails the runtime dry-run; populate its cache
before running the checks.

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Each Terraform line installs its package with the expected warning behavior | `eval.line-1.14`, `eval.line-1.15`, `eval.line-1.16` |
| Selected lines coexist; the newest package supplies `terraform` | `eval.allLines`, `run.allLines` |
| The evaluated system declares Terraform unfree permission through NixOS | `eval.unfreeDeclaration` |
| Versioned commands initialize, validate and plan local output-only HCL without a backend or provider | `run.commands-1.14`, `run.commands-1.15`, `run.commands-1.16` |

No test provisions infrastructure.
