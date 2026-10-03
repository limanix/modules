# Cloud tools

Installs AWS CLI v2 and the Google Cloud CLI inside the VM. Use the same Linux
shell and mounted project as your builds and container tools.

```toml
[nixos]
modules = ["lmx:cloud-tools"]
```

Add the selector to `nixos.modules` and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
Cozy already includes this module.

## Versions

Both packages come from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
The module has no version lines; AWS uses the v2 package. Check installed
versions inside the VM:

```console
aws --version
gcloud version
```

## Use

Configure authentication for the VM's account using your organization's approved
method. Host credentials are not copied into the guest. For an existing
authenticated AWS profile, inspect its configuration and identity:

```console
aws configure list --profile dev
aws sts get-caller-identity --profile dev
```

Replace `dev` with your configured profile. The identity command contacts AWS;
it does not create resources. For an existing Google Cloud configuration:

```console
gcloud config list
gcloud auth list
```

Check the active account and project before running project commands.
Application Default Credentials are separate from the CLI's own login; configure
them only when your application's workflow requires them.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native AWS profiles and Google Cloud configurations; no catalog-specific public options |
| AWS state | Normally `~/.aws/config` and `~/.aws/credentials`; AWS environment overrides retain their native behavior |
| Google Cloud state | Normally `~/.config/gcloud/`; `CLOUDSDK_CONFIG` selects another configuration directory |
| Integration | Cozy imports this entry point; the tools can also be selected alone |
| Services and capabilities | No startup units, cloud resources or language-support declarations |

Store personal credentials through the selected tool's authentication mechanism.
Keep them out of Nix modules and guest-wide TOML environment settings.

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Installed command lacks access | Authenticate for the guest account and confirm the active profile or configuration |
| CLI login works but an application fails | Check that application's credential mechanism, including ADC when applicable |
| Wrong project or region | Pass explicit project/profile/region flags or select the intended configuration |
| Missing gcloud component | Packages are managed by Nix; add required tools through a module rather than modifying the Nix store |
| VM deletion | The managed home normally survives; deliberate home removal also removes credentials stored there |

## Guarantees

| Guarantee | Covered by |
| -- | -- |
| Installs base Nixpkgs AWS CLI v2 and Google Cloud SDK packages | `check.nix` |
| Selecting cloud clients adds no startup units or activation commands | `tests.nix`: noStartup |
| Both version commands run with an isolated home without authentication | `smoke.nix`: commands |
