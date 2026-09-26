# Write your first module

Add `curl`, `jq`, and `ripgrep` to a VM with a custom NixOS module.
You will create the source files, register a copy with Limanix, and select it in your VM configuration.

**Before you start:** install Limanix and choose a project directory on your Mac.
All commands run on your **Mac** unless marked **inside the VM**.

## 1. Create the files

From your project directory:

```console
mkdir -p modules/dev-tools
```

Create these two files:

```text
my-project/
├── limanix.toml
└── modules/
    └── dev-tools/
        ├── default.nix
        └── tools.nix
```

**`modules/dev-tools/default.nix`** is the entry point:

```{literalinclude} examples/dev-tools/default.nix
:language: nix
```

**`modules/dev-tools/tools.nix`** selects the packages:

```{literalinclude} examples/dev-tools/tools.nix
:language: nix
```

| Nix expression | What it does |
|---|---|
| `imports = [ ./tools.nix ];` | Includes the file beside `default.nix` |
| `pkgs.jq` | Selects the `jq` package from the VM's Nixpkgs package set |
| `environment.systemPackages` | Makes these programs available to users inside the VM |

A small module can keep everything in `default.nix`.
This example uses a second file to show how relative imports work.

Download: {download}`default.nix <examples/dev-tools/default.nix>` · {download}`tools.nix <examples/dev-tools/tools.nix>`.

## 2. Register the module

```console
limanix modules add dev-tools ./modules/dev-tools
limanix modules list
```

The list now includes **`third-party:dev-tools`**.
Registration copies the files without evaluating Nix; see [Import a module](https://limanix.dev/categories/client/modules.html#import-a-module) for the command's requirements and [Module names](https://limanix.dev/categories/client/modules.html#module-names) for valid names.

## 3. Apply it to a VM

```{warning}
Updating interrupts running work in the VM; see [Apply a configuration change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).
```

**Existing `module-lab` VM:** add `third-party:dev-tools` to its `nixos.modules` list, keeping the other settings.
Run `limanix update --config limanix.toml`, then enter with `limanix shell module-lab` and continue with the version commands below.

**For a new VM**, save this complete configuration as **`limanix.toml`** in your project directory on your Mac:

```{literalinclude} examples/module-lab.toml
:language: toml
```

Use `arch = "amd64"` on an Intel Mac.
The example does not add application firewall ports and shares no project directory.

Download: {download}`limanix.toml <examples/module-lab.toml>`.

Create the VM and enter its shell:

```console
limanix create --config limanix.toml
limanix shell module-lab
```

Run **inside the VM**:

```console
curl --version
jq --version
rg --version
```

Each command prints its installed version.
Run `exit` to return to your Mac.

## 4. Make a change

Add `pkgs.tree` to the package list in your source `tools.nix`.
Follow [Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) to refresh the copy of `dev-tools` and apply it:

```console
limanix modules remove dev-tools
limanix modules add dev-tools ./modules/dev-tools
limanix update --config limanix.toml
limanix shell module-lab -- tree --version
```

The last command prints the version of `tree` inside the updated VM.

## Add a web service

Packages provide programs; NixOS service options also configure how a daemon runs.
To try this, save **`modules/dev-tools/web.nix`**:

```{literalinclude} examples/dev-tools/web.nix
:language: nix
```

Replace the `imports` line in `default.nix` with:

```nix
imports = [ ./tools.nix ./web.nix ];
```

Repeat the remove, add, and update commands from the previous step.
Then enter the VM with `limanix shell module-lab` and run:

```console
curl http://127.0.0.1/
systemctl status nginx
```

The HTTP response is `Hello from Limanix`.
The service status should show `active (running)`.

Run `exit` to return to your Mac.
To reach the server from your Mac, edit the existing firewall table in your project's `limanix.toml` on the Mac:

```toml
[network.ports]
tcp = [80]
udp = []
```

Apply the TOML change on your Mac:

```console
limanix update --config limanix.toml
limanix list
```

Open `http://<ADDRESS>/`, replacing `<ADDRESS>` with the VM address shown in the list.

```{note}
`network.ports` opens ports in the guest firewall.
Use the VM's address to reach the service from your Mac.
This setting does not forward the service to your Mac's `localhost`.
```

## Keep the source portable

Nix resolves a path such as `./tools.nix` relative to the file containing it.
Keep these files inside the module directory; see [Keep imports self-contained](https://limanix.dev/categories/client/modules.html#keep-imports-self-contained) for what Limanix can copy.

The `default.nix` entry point does not need a `module.toml` or `flake.nix` for a personal module.
Catalog metadata is covered in [Contributing to the catalog](contributing.md).

```{warning}
Modules can configure privileged services and access directories shared with the VM.
Use code you trust and keep credentials out of Nix source.
Source files can enter the Nix store; see {ref}`Source files and the Nix store <module-nix-store>`.
```

(module-runtime)=
## Read VM settings with `runtime`

Limanix passes `runtime` as an argument to NixOS modules when evaluating the VM configuration.
It contains the following fields:

| Field | Nix type | Value |
| --- | --- | --- |
| `runtime.name` | string | VM name from `name`, also used as the guest hostname |
| `runtime.arch` | string | Guest architecture from `resources.arch`: `"arm64"` or `"amd64"` |
| `runtime.user.name` | string | Guest account name from `user.name` |
| `runtime.user.home` | string | Absolute guest home path from `user.home` |
| `runtime.user.uid` | integer | UID of the Mac user running Limanix, reused for the guest account |
| `runtime.user.sudo` | boolean | Whether `user.sudo` enables passwordless sudo for the guest account |
| `runtime.ports.tcp` | list of integers | Guest firewall ports from `network.ports.tcp` |
| `runtime.ports.udp` | list of integers | Guest firewall ports from `network.ports.udp` |
| `runtime.modules` | list of strings | Generated module entry paths relative to the VM's flake directory, such as `modules/0000/default.nix` |

The configuration values include defaults for settings omitted from TOML.
They describe the client's inputs, not the final NixOS settings after all modules are combined.
`runtime.arch` uses Limanix's architecture names: `"arm64"` maps to Nix's `"aarch64-linux"`, and `"amd64"` maps to `"x86_64-linux"`.
The UID comes from the host; there is no `user.uid` TOML setting.

```{note}
`runtime.modules` contains resolved import paths, not the `lmx:` or `third-party:` selectors from `nixos.modules`.
Limanix already imports these entries into the VM configuration.
```

For settings that belong to the guest account, use `runtime.user.name` instead of assuming the username is `dev`:

```nix
{ pkgs, runtime, ... }:
{
  users.users.${runtime.user.name}.packages = [ pkgs.jq ];
}
```

`runtime` is specific to Limanix.
To use a module that requires it in a standalone NixOS configuration, supply the argument through `specialArgs`.

[Module concepts](concepts.md) explains which settings belong in TOML and which belong in a module.

Continue with [Make a module configurable](reusable-modules.md) when projects need different settings for the same feature.
