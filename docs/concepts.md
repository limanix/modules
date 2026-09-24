# Understand modules

A module describes part of the Linux environment you want. 
It can add tools, enable a service, or set its configuration. 
Start with a small file and combine it with other modules as your environment grows.

You do not need to learn all Nix to use the [catalog](catalog.md). 
This page explains enough to read a module and start writing your own.

## Five names you will meet

| Name               | What it means here                                                             |
|--------------------|--------------------------------------------------------------------------------|
| **Nix language**   | The language used in `.nix` files. It describes values and functions.          |
| **Nix**            | The tool that evaluates those expressions and builds or obtains their results. |
| **Nixpkgs**        | A collection of package definitions, library helpers, and NixOS modules.       |
| **NixOS**          | The Linux operating system whose configuration is assembled from modules.      |
| **Limanix module** | A NixOS module selected for a Limanix VM.                                      |

The [NixOS manual](https://nixos.org/manual/nixos/stable/) introduces how these parts fit together. 
A module changes the **guest Linux system**. 
Adding a package to a module does not install a macOS application.

## Describe the result

For a command-line tool, a module can be this small:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
}
```

This requests `jq` in the system environment. 
NixOS uses the package definition to obtain the required files when the configuration is built and applied.

| A package                       | A module                                                  |
|---------------------------------|-----------------------------------------------------------|
| Provides software and its files | Defines how software becomes part of the system           |
| Example: `pkgs.jq`              | Example: adding `pkgs.jq` to `environment.systemPackages` |

Installing a program and enabling a service are different operations. 
A service may also need a systemd unit, configuration files, and a dedicated user. 
Prefer its NixOS option when available, such as `services.postgresql.enable`.

See [declarative package management](https://nixos.org/manual/nixos/stable/#sec-declarative-package-mgmt) for the package and service distinction.

## Read a small Nix file

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.jq
    pkgs.ripgrep
  ];
}
```

| Syntax                       | Read it as                                                  |
|------------------------------|-------------------------------------------------------------|
| `{ pkgs, ... }:`             | A function that asks for `pkgs` and accepts other arguments |
| The second `{ ... }`         | An attribute set: named values returned by the function     |
| `environment.systemPackages` | A nested option name                                        |
| `pkgs.jq`                    | The `jq` package in the supplied package set                |
| `[ ... ]`                    | A list; its entries have no separating commas               |
| `;`                          | The end of an assignment                                    |

The module system supplies arguments to module functions. Common arguments are:

- `pkgs`: packages for the system being configured.
- `lib`: helpers, including option declarations and merge controls.
- `config`: the combined configuration from all participating modules.
- `...`: allows arguments that this function does not name.

A module that needs none of these arguments can be a plain attribute set:

```nix
{
  programs.git.enable = true;
}
```

For more syntax examples, use the official
[Nix language introduction](https://nix.dev/tutorials/nix-language.html).

## Find a package or service option

| You need…                   | Look in                                                   | Use the result in                                      |
|-----------------------------|-----------------------------------------------------------|--------------------------------------------------------|
| A command-line program      | [NixOS package search](https://search.nixos.org/packages) | `environment.systemPackages`                           |
| A configured system service | [NixOS option search](https://search.nixos.org/options)   | The service's options, such as `services.nginx.enable` |

Use the package attribute, which can differ from the command name. 
For example, `pkgs.ripgrep` supplies the `rg` command. 
Read an option's type, default, and description before setting it.

Choose documentation for the NixOS release used by your client. 
An option shown for a newer release may not exist in your guest's configuration.

## Combine files with `imports`

```text
dev-tools/
├── default.nix
└── tools.nix
```

The entry point, `default.nix`, includes the other file:

```nix
{
  imports = [ ./tools.nix ];
}
```

`./tools.nix` is relative to the Nix file containing that path. 
It is not relative to the terminal's current directory. 
Keep a custom module's supporting files inside its directory; the [writing guide](writing-modules.md) explains how to register that directory with LimaNix.

### `imports` and `import` are different

| Form                         | Purpose                                           |
|------------------------------|---------------------------------------------------|
| `imports = [ ./tools.nix ];` | Adds modules to the configuration being assembled |
| `import ./settings.nix`      | Evaluates a Nix file and returns its value        |

Use **`imports` to compose NixOS modules**. 
The singular `import` is a general Nix function. 
Its result can be a number, a set, another function, or a module. 
It does not automatically provide `pkgs`, `lib`, or `config` to a function it loads.

References: [splitting modules](https://nix.dev/tutorials/module-system/deep-dive.html#splitting-modules)
and the [Nix `import` function](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-import).

## Modules contribute to one configuration

**Import order is not a general override mechanism.** 
Each option's type and definition priorities determine how its values combine.

| Definitions in two modules                                          | Result                              |
|---------------------------------------------------------------------|-------------------------------------|
| `environment.systemPackages = [ pkgs.jq ];` and `[ pkgs.ripgrep ];` | Both packages are included          |
| Two ordinary, different values for `networking.hostName`            | A conflicting-definition error      |
| A `lib.mkDefault` value and an ordinary value                       | The ordinary value takes precedence |

The [reusable module guide](reusable-modules.md) shows how to expose options and choose defaults without relying on file order.

(module-nix-store)=
## Source files and the Nix store

Nix stores build results and source inputs under paths such as `/nix/store/…`.
Store objects are immutable: edit your source module and apply an updated configuration instead of editing store files. 
A store path also identifies the files used by other build results. 
See the [Nix store overview](https://nix.dev/manual/nix/2.35/store/).

```{important}
Do not put passwords, tokens, or private keys in module source files. 
Files and values used to build the system can enter the world-readable Nix store. 
Use the service's supported runtime secret-file mechanism when one is available.
```

The NixOS manual illustrates this distinction with [Keycloak credential files](https://nixos.org/manual/nixos/stable/#module-services-keycloak-database):
a runtime filename and a Nix path copied into the store are not interchangeable.

Next, [use catalog modules](using-modules.md) or [write your first module](writing-modules.md).
