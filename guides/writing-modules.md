---
myst:
  heading_anchors: 2
---

# Write a module

Write a custom module when you need software or settings that the catalog does not provide.
A custom module is a directory with a `default.nix` file.
It needs no catalog metadata and no flake.

## Create a module

Keep a project's modules in its repository, one directory per module:

```text
my-project/
├── limanix.toml
└── modules/
    └── dev-tools/
        └── default.nix
```

Save this as `modules/dev-tools/default.nix`:

```{literalinclude} examples/dev-tools/default.nix
:language: nix
```

The module adds `jq` and `ripgrep` to the VM.
[NixOS basics](nixos-basics.md) explains the syntax, and the [package search](https://search.nixos.org/packages) finds other packages.

Download: {download}`default.nix <examples/dev-tools/default.nix>`.

## Use it in a VM

On your Mac, import the directory from the project root:

```console
limanix modules add dev-tools ./modules/dev-tools
```

Add its selector to `nixos.modules`, next to the modules that the VM already uses:

```toml
[nixos]
modules = ["lmx:git", "third-party:dev-tools"]
```

Then [apply the configuration change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).
Inside the VM, the `jq` and `rg` commands are now available.

The client imports a copy of the directory.
After you edit the module, [replace the imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) and update the VM again.

## Configure programs and services

Use options when you need more than commands on `PATH`.
This module installs Neovim and makes it the default editor:

```nix
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
```

It takes no arguments because it only sets options.

Services work the same way.
This module runs PostgreSQL and creates a database and a database user named after the VM's user:

```{code-block} nix
:linenos:
:name: custom-module-postgresql
:class: code-example

{ runtime, ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ runtime.user.name ];
    ensureUsers = [
      {
        name = runtime.user.name;
        ensureDBOwnership = true;
      }
    ];
  };
}
```

| Code | Purpose |
| --- | --- |
| [1](#custom-module-postgresql.1){.external .code-lines} | Receives the VM's settings through the [`runtime` argument](#read-vm-settings-with-runtime) |
| [4](#custom-module-postgresql.4){.external .code-lines} | Enables the PostgreSQL service |
| [5](#custom-module-postgresql.5){.external .code-lines} | Creates a database named after the VM's user |
| [6–11](#custom-module-postgresql.6-11){.external .code-lines} | Creates a database user with the same name and makes it the owner of that database |

After the update, running `psql` inside the VM connects to that database without a password.
Each service documents its options, including the ones it requires, in the [option search](https://search.nixos.org/options).
Keep passwords out of modules; see [Trust and secrets](concepts.md#trust-and-secrets).

## Split a module into files

A larger module can import other files through its entry point:

```text
dev-tools/
├── default.nix
├── tools.nix
└── editor.nix
```

```nix
{
  imports = [ ./tools.nix ./editor.nix ];
}
```

Each imported file is a module of its own, such as the package list and the Neovim example above.
Paths are relative to the file that contains them.
Keep every imported file inside the module directory, because the client copies only that directory; see [Keep imports self-contained](https://limanix.dev/categories/client/modules.html#keep-imports-self-contained).

`imports` combines modules.
The Nix function `import ./file.nix` is different: it evaluates a file and returns its value.

## Combine with other modules

NixOS merges your module with the base system and every other selected module:

| Definitions in different modules | Result |
| --- | --- |
| Lists, such as `environment.systemPackages` | Combined |
| Two different values for a single-value option | The build stops with a `conflicting definition values` error |
| A value wrapped in `lib.mkDefault`, and an ordinary value | The ordinary value wins |
| A value wrapped in `lib.mkForce` | Replaces definitions with weaker priority, including ordinary values and `lib.mkDefault` |

Use `lib.mkDefault` for a value that other modules may replace:

```nix
{ lib, ... }:
{
  environment.variables.EXAMPLE_BUILD_MODE = lib.mkDefault "development";
}
```

Another module can then set `environment.variables.EXAMPLE_BUILD_MODE = "test";` without a conflict.
The order of `nixos.modules` does not resolve conflicts.
Use `lib.mkForce` for intentional replacement; for list options, it replaces entire lists from weaker definitions.
Definitions with the same priority still merge or conflict.

When two packages provide the same command, NixOS keeps one of them on `PATH` and the build succeeds.
To choose which one, raise the priority of the package you want:

```nix
{ lib, pkgs, ... }:
{
  environment.systemPackages = [ (lib.hiPrio pkgs.netcat-openbsd) ];
}
```

Catalog modules that support side-by-side versions already set package priorities.
Their newest selected line supplies the ordinary commands.
Inside the VM, `readlink -f "$(command -v nc)"` shows which package provides a command.

To give a module its own settings, such as an `enable` switch, see [option declarations](https://nixos.org/manual/nixos/stable/#sec-option-declarations) and [conditional definitions with `mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) in the NixOS manual.

## Read VM settings with `runtime`

Limanix passes a `runtime` argument that contains the VM's settings.
Use it instead of hard-coding values, such as the user name `dev`:

```nix
{ pkgs, runtime, ... }:
{
  users.users.${runtime.user.name}.packages = [ pkgs.jq ];
}
```

| Field | Type | Value |
| --- | --- | --- |
| `runtime.name` | string | VM name, also used as the hostname |
| `runtime.arch` | string | `"arm64"` or `"amd64"`, which Nix calls `aarch64-linux` and `x86_64-linux` |
| `runtime.user.name` | string | Guest account name, from `user.name` |
| `runtime.user.home` | string | Guest home directory, from `user.home` |
| `runtime.user.uid` | integer | UID of the Mac user running Limanix; `limanix.toml` has no UID setting |
| `runtime.user.sudo` | boolean | Whether the guest account has passwordless `sudo`, from `user.sudo` |
| `runtime.ports.tcp` | list of integers | Firewall ports from `network.ports.tcp` |
| `runtime.ports.udp` | list of integers | Firewall ports from `network.ports.udp` |
| `runtime.modules` | list of strings | Paths of the selected modules' copies, such as `modules/0000/default.nix`; Limanix already imports them |

The values come from `limanix.toml`, with defaults applied for omitted settings.
They do not reflect changes that modules make.
`runtime` exists only in Limanix; to reuse a module in another NixOS configuration, pass the argument through NixOS `specialArgs`.

## Next steps

- [Native dependencies](native-dependencies.md): build or run code that needs system libraries.
- [Troubleshooting](troubleshooting.md): fix errors that a module causes.
- [Catalog development](extending-catalog.md): add a module to the catalog.
