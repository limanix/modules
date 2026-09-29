# Terraform

Installs the Terraform CLI for infrastructure as code.

```toml
[nixos]
modules = ["lmx:terraform"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                              | Terraform | Notes   |
|---------------------------------------|-----------|---------|
| `lmx:terraform`, `lmx:terraform-1.16` | 1.16.4    | Default |
| `lmx:terraform-1.15`                  | 1.15.9    |         |
| `lmx:terraform-1.14`                  | 1.14.9    |         |

Terraform uses the [Business Source License 1.1](https://github.com/hashicorp/terraform/blob/v1.16.4/LICENSE).
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
