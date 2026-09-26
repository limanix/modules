# Make a module configurable

Use options when several projects need the same feature with different settings.
This guide turns the tools from [Write your first module](writing-modules.md) into a feature that each project can enable and customize.

## 1. Separate the feature from its settings

Run on your **Mac**, from your project directory:

```console
mkdir -p modules/configurable-tools
```

The directory will contain two files:

| File | Purpose |
|---|---|
| `module.nix` | Defines the available settings and what they do |
| `default.nix` | Imports the feature and chooses settings for this project |

Create **`modules/configurable-tools/module.nix`**:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.example.devTools;
in
{
  options.example.devTools = {
    enable = lib.mkEnableOption "development command-line tools";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.jq ];
      description = "Packages to install when development tools are enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = cfg.packages;
  };
}
```

The `options` section declares the settings that other modules may use.
The `config` section applies the chosen settings to the VM.
`cfg` is a short name for the final values under `config.example.devTools`.

| Setting | Accepted value | Default | Effect |
|---|---|---|---|
| `example.devTools.enable` | `true` or `false` | `false` | Enables this module's package selection |
| `example.devTools.packages` | A list of Nix packages | `[ pkgs.jq ]` | Selects the packages to install when enabled |

```{note}
`example.devTools` is a name chosen for this tutorial, not a built-in Limanix setting.
Choose your own namespace for modules you share.
```

## 2. Choose the project's settings

Create **`modules/configurable-tools/default.nix`**:

```nix
{ pkgs, ... }:
{
  imports = [ ./module.nix ];

  example.devTools = {
    enable = true;
    packages = [ pkgs.jq pkgs.ripgrep ];
  };
}
```

This enables the feature with `jq` and `ripgrep`.
Removing the `packages` line selects the default, `jq`.
Removing `enable = true` leaves the feature disabled and adds no packages from this module.

```{tip}
Use package values such as `[ pkgs.jq ]`, not strings such as `[ "jq" ]`.
The option's type check rejects strings before the system is built.
```

## 3. Apply it to your VM

Register the complete directory on your **Mac**:

```console
limanix modules add configurable-tools ./modules/configurable-tools
```

In the existing `limanix.toml` for `module-lab`, replace `third-party:dev-tools` with `third-party:configurable-tools`:

```toml
[nixos]
modules = ["third-party:configurable-tools"]
```

Keep any other module selections the VM needs.

```{warning}
Updating interrupts running work in the VM; see [Apply a configuration change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).
```

Apply the configuration and check both commands:

```console
limanix update --config limanix.toml
limanix shell module-lab -- jq --version
limanix shell module-lab -- rg --version
```

Both commands print their installed versions.

After later source edits, [replace the imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module), using the name `configurable-tools` and source directory `./modules/configurable-tools`.

(understand-how-settings-combine)=
## Understand how settings combine

NixOS combines the settings from all selected modules.
What happens when two modules set the same option depends on its type and the priority of each definition.

A shared module can provide a default for an environment variable:

```nix
{ lib, ... }:
{
  environment.variables.EXAMPLE_BUILD_MODE = lib.mkDefault "development";
}
```

With this definition alone, `EXAMPLE_BUILD_MODE` is `development` inside the VM.
This is an example variable with no built-in meaning to Limanix.
A project module can override the default:

```nix
{
  environment.variables.EXAMPLE_BUILD_MODE = "test";
}
```

The resulting `EXAMPLE_BUILD_MODE` value is `test`.

| Definitions for `EXAMPLE_BUILD_MODE` | Result |
|---|---|
| Shared `lib.mkDefault "development"` only | `development` |
| Shared default and ordinary `"test"` | `test` |
| Ordinary `"test"` and ordinary `"release"` | An evaluation error |

The same distinction matters for `example.devTools.packages`:

- Its declared `default = [ pkgs.jq ];` is used when no stronger definition is present.
- A project setting `packages = [ pkgs.ripgrep ];` replaces that default.
- Two ordinary definitions of `packages` combine their lists.

```{warning}
Changing import order does not resolve conflicting ordinary values of `EXAMPLE_BUILD_MODE`.
Fix the conflicting settings or make one a default.
`lib.mkForce` replaces weaker definitions, including entire package lists; it can discard packages added by other modules.
Use it only when you intend that replacement.
```

See the [NixOS manual on option definitions](https://nixos.org/manual/nixos/stable/#sec-option-definitions) for merge and priority rules.

## Keep the feature conditional

The example uses `lib.mkIf` to apply settings only when the feature is enabled:

```nix
config = lib.mkIf cfg.enable {
  environment.systemPackages = cfg.packages;
};
```

Keep the imported files fixed and put conditions around their settings.
An ordinary `if` around the entire `config` section can cause infinite recursion when its condition reads `config` itself.
The [NixOS manual on delayed conditions](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) explains why `mkIf` avoids that problem.

## Before sharing the module

- Describe each option, its default, and its effect.
- Include an entry point that demonstrates how to enable the feature.
- Keep all imported files inside the module directory.
- Check the enabled and disabled cases, including use alongside another module that adds packages.
- Keep credentials and private machine paths out of the source.

For catalog conventions, continue with [Contributing to the catalog](contributing.md).
For evaluation errors, see [Troubleshooting](troubleshooting.md).
