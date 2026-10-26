# Google Cloud CLI

Installs the Google Cloud CLI.

```toml
[nixos]
modules = ["lmx:gcloud"]
```

Add the selector to `nixos.modules` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change).

## Versions

The package comes from the catalog's
[nixos-unstable revision](../../README.md#package-pins-and-unfree-permissions),
which the Check update flow moves every week. This module has no version lines.

```console
gcloud version
```

## Use

Authenticate for the guest account using your organization's approved method.
For an existing configuration:

```console
gcloud config list
gcloud auth list
```

Check the active account and project before running project commands.
Application Default Credentials are separate from the CLI's own login. Configure
them when your application requires them.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native Google Cloud configurations; no catalog-specific public options |
| State | Normally `~/.config/gcloud/`; `CLOUDSDK_CONFIG` selects another directory |
| Integration | Needs no other module; `[env]` and a mount can select a configuration directory from the Mac |
| Activation | Adds no startup units, activation commands or cloud resources |

Host credentials are not copied into the guest. Keep credentials out of Nix
modules and guest-wide TOML environment settings.

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Command installed but access denied | Authenticate for the guest account and check the active account and project |
| CLI login works but an application fails | Check that application's credential mechanism, including ADC when applicable |
| Missing component | Packages are managed by Nix; add tools through a module rather than modifying the Nix store |
| VM deletion | The managed home normally survives; deliberate home removal also removes credentials stored there |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Adds the Google Cloud SDK of the catalog's nixos-unstable revision without unrelated profile packages | `eval.package` |
| Adds no startup units or activation commands | `eval.noStartup` |
| The system-profile version command runs offline with an isolated home | `run.commands` |
| `gke-gcloud-auth-plugin` is on the system profile and runs | `run.commands` |
