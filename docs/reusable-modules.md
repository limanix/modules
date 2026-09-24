# Make a module configurable

A small module can set values directly. 
Add options when several projects need the same behavior with different settings.

This example creates a configurable set of development tools. 
Complete [your first module](writing-modules.md) before extending it with this pattern.

## Separate the feature from its settings

Keep the feature definition and the project's choices in separate files:

```text
modules/configurable-tools/
├── default.nix
└── module.nix
```

| File          | Responsibility                                                |
|---------------|---------------------------------------------------------------|
| `module.nix`  | Declares options and implements the feature                   |
| `default.nix` | Imports the feature and chooses settings for this module tree |

Here, `example.devTools` is an **example option namespace**. 
Choose a name for your own module; it is not a LimaNix API or a required naming scheme.

From your project directory, create a new tree for this example:

```console
mkdir -p modules/configurable-tools
```

## 1. Declare the options

Create `modules/configurable-tools/module.nix`:

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

The module has two parts:

- **`options` declares the interface**: allowed names, types, defaults, and help text.
- **`config` implements it**: the definitions contributed to the system.

The function argument `config` holds the merged result from all modules. 
The returned `config` attribute holds this module's contributions. 
`cfg` is just a local name that shortens `config.example.devTools`.

| Helper                       | Role in this example                                               |
|------------------------------|--------------------------------------------------------------------|
| `mkEnableOption`             | Declares a boolean switch, disabled by default                     |
| `mkOption`                   | Declares a configurable value                                      |
| `types.listOf types.package` | Requires a list of packages rather than package-name strings       |
| `mkIf cfg.enable`            | Contributes the package definition only when the switch is enabled |

The official [basic module tutorial](https://nix.dev/tutorials/module-system/a-basic-module/index.html) explains declarations and definitions. 
The [module system guide](https://nix.dev/tutorials/module-system/deep-dive.html) explains how the `config` argument relates to them.

## 2. Choose settings in the entry point

Create `modules/configurable-tools/default.nix`:

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

This enables the feature and selects two packages. 
Without the `packages` assignment, the declared default supplies only `jq`. Without `enable = true`, the feature adds no packages.

**Use Nix package values:** `[ pkgs.jq ]` is correct here. 
`[ "jq" ]` is a list of strings and fails this option's type check.

## 3. Register the complete directory

From your project directory, run on your Mac:

```console
limanix modules add configurable-tools ./modules/configurable-tools
```

Select the registered module in your VM configuration:

```toml
[nixos]
modules = ["third-party:configurable-tools"]
```

Preserve any other modules that the VM needs. 
Follow [using modules](using-modules.md) to create or update the VM and verify the tools inside it.

Limanix registers the directory as a copy. 
After editing the source, refresh the registered copy as described in the [writing guide](writing-modules.md), then update the VM.

## Choose defaults deliberately

These three forms solve different problems:

| Form                             | Use it for                                                |
|----------------------------------|-----------------------------------------------------------|
| `default = …;` inside `mkOption` | The fallback for an option your module declares           |
| `some.option = lib.mkDefault …;` | A suggested value that an ordinary definition can replace |
| `some.option = lib.mkForce …;`   | An explicit override of ordinary and default definitions  |

For example, one module can suggest an editor:

```nix
{ lib, ... }:
{
  environment.variables.EDITOR = lib.mkDefault "vi";
}
```

Another module can choose a different editor:

```nix
{
  environment.variables.EDITOR = "nano";
}
```

The final value is `nano`. Two different ordinary definitions would conflict.
Two different `mkDefault` definitions can also conflict: they have equal priority.
Changing import order does not resolve that conflict.

For a list option, ordinary definitions normally combine. 
In the earlier example, two ordinary definitions of `example.devTools.packages` contribute to the same package list; 
they do not replace each other. 
An ordinary definition does replace the option's `default` value.

```{warning}
`mkForce` affects the entire option definition. 
Forcing `environment.systemPackages` can discard packages contributed by other modules.
Use it only when replacing those contributions is the intended result. 
It is not a routine fix for a merge error.
```

The [module system implementation](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/lib/modules.nix) defines these priority rules. 
Definitions at the winning priority still need to merge successfully; `mkForce` does not make incompatible values compatible.

## Keep conditions inside `config`

Use `lib.mkIf` for definitions controlled by module options:

```nix
config = lib.mkIf cfg.enable {
  environment.systemPackages = cfg.packages;
};
```

Avoid wrapping the entire `config` attribute in an ordinary `if` that reads `config` itself. 
Evaluating the condition can require the same configuration that is still being constructed. 
Keep the imported module set fixed and make its definitions conditional instead.

See [delaying conditionals](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) for the recursion problem and the role of `mkIf`.

## Before sharing

- Explain each option's effect and default.
- Include a complete `default.nix` that enables the example.
- Keep imported files inside the module directory.
- Check the disabled case as well as the enabled case.
- Check the behavior alongside another module that adds packages.
- Keep credentials and machine-specific private paths out of the source.

For the repository's checks and catalog structure, continue with [contributing modules](contributing.md). 
For failed evaluations, see [troubleshooting](troubleshooting.md).
