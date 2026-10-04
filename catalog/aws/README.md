# AWS CLI

Installs AWS CLI v2 inside the VM. Select it for AWS commands from your Linux
shell and mounted project. Cozy includes this module.

```toml
[nixos]
modules = ["lmx:aws"]
```

Add the selector to `nixos.modules` and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

The package comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.

```console
aws --version
```

## Use

Authenticate for the guest account using your organization's approved method.
For an existing profile:

```console
aws configure list --profile dev
aws sts get-caller-identity --profile dev
```

Replace `dev` with your configured profile. The identity command contacts AWS.
Check the account and region before running project commands.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native AWS profiles and environment variables; no catalog-specific public options |
| State | Normally `~/.aws/config` and `~/.aws/credentials`; native path overrides still apply |
| Integration | Cozy imports this entry point; `lmx:aws` can be selected alone |
| Activation | Adds no startup units, activation commands or cloud resources |

Host credentials are not copied into the guest. Keep credentials out of Nix
modules and guest-wide TOML environment settings.

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Command installed but access denied | Authenticate for the guest account and confirm the selected profile |
| Wrong account or region | Use an explicit `--profile` or `--region` |
| VM deletion | The managed home normally survives; deliberate home removal also removes credentials stored there |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Adds base Nixpkgs AWS CLI v2 without unrelated profile packages | `eval.package` |
| Adds no startup units or activation commands | `eval.noStartup` |
| The system-profile version command runs offline with an isolated home | `run.commands` |
