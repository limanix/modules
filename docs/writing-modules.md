# Write your first module

This tutorial adds `curl`, `jq`, and `ripgrep` to a VM. 
You will create a small module directory, import it into Limanix, and apply it to a guest.

All file creation and `limanix` commands below run on your **Mac**. 
Commands explicitly marked **inside the VM** run in the guest shell.

## 1. Create the source tree

Keep the module beside your project configuration:

```text
my-project/
├── limanix.toml
└── modules/
    └── dev-tools/
        ├── default.nix
        └── tools.nix
```

From `my-project`, create the directory:

```console
mkdir -p modules/dev-tools
```

Save `modules/dev-tools/default.nix`:

```{literalinclude} examples/dev-tools/default.nix
:language: nix
```

Save `modules/dev-tools/tools.nix`:

```{literalinclude} examples/dev-tools/tools.nix
:language: nix
```

`default.nix` is the entry point Limanix imports. 
Its `imports` list includes the other file. 
`environment.systemPackages` adds packages to the guest's system environment.

A small module may put that package definition directly in `default.nix`.
The two-file layout shows how to keep a growing module organized.

Download the examples:
{download}`default.nix <examples/dev-tools/default.nix>` ·
{download}`tools.nix <examples/dev-tools/tools.nix>`.

## 2. Import the directory

From `my-project`, run:

```console
limanix modules add dev-tools ./modules/dev-tools
limanix modules list
```

The new identifier is `third-party:dev-tools`.

| Argument              | Meaning                                                 |
|-----------------------|---------------------------------------------------------|
| `dev-tools`           | The local registry name; pass it without `third-party:` |
| `./modules/dev-tools` | A directory relative to your current shell directory    |

Names use lowercase letters, digits, and single separating hyphens. 
Start with a letter and keep the name within 63 characters: `dev-tools` is valid, `Dev_Tools` is not.

**Importing copies the directory.** 
It neither enables the module in a VM nor evaluates its Nix code. 
Syntax and option errors appear when the guest configuration is evaluated during create or update.

## 3. Select and apply it

For a new VM, save this complete `limanix.toml`:

```{literalinclude} examples/module-lab.toml
:language: toml
```

Use `arch = "amd64"` on an Intel Mac.
You can also {download}`download this configuration <examples/module-lab.toml>`.

Already created `module-lab` in the previous guide? 
Replace its module selection with `third-party:dev-tools` and use `limanix update --config limanix.toml` instead of `create` below. 
You can keep catalog selectors in the same list.

```console
limanix create --config limanix.toml
limanix shell module-lab
```

Inside the **VM**:

```console
curl --version
jq --version
rg --version
```

Run `exit` to return to your Mac before continuing.

## 4. Change the module

Add `pkgs.tree` to the package list in `tools.nix`. 
Refresh the imported copy, then update the VM:

```console
limanix modules remove dev-tools
limanix modules add dev-tools ./modules/dev-tools
limanix update --config limanix.toml
limanix shell module-lab -- tree --version
```

Keep your source directory: `remove` deletes the registry copy, not the source you imported. 
The current CLI has no in-place replacement flag.

```mermaid
flowchart LR
    accTitle: A custom module moves through two copies before it runs
    accDescr: modules add copies your directory into the registry. create or update copies the registry module into the VM configuration and rebuilds the guest.
    source["Source files"] --> registry["Registry copy"]
    registry --> guest["VM snapshot"]
```

| You changed…                   | Next action                                                     |
|--------------------------------|-----------------------------------------------------------------|
| A file in the source directory | Remove and re-add the import, then update each VM that needs it |
| The module list in TOML        | Update that VM                                                  |
| Only the local registry        | Update the VM to use the new copy                               |

An update restarts the VM. 
Existing VMs keep their own configuration snapshots; removing a registry entry does not remove its configuration from those guests.

## Add a service

A package supplies a program. 
A NixOS service option also configures how a daemon runs. 
For example, save this as `modules/dev-tools/web.nix`:

```{literalinclude} examples/dev-tools/web.nix
:language: nix
```

Add `./web.nix` to the `imports` list in `default.nix`. 
Re-import the directory and update the VM as above.

Check from inside the **VM**:

```console
curl http://127.0.0.1/
systemctl status nginx
```

The response should be `Hello from Limanix`. 
To reach this server from your Mac, change the existing firewall table in TOML:

```toml
[network.ports]
tcp = [80]
udp = []
```

Apply the TOML change, run `limanix list` on your Mac, and open `http://<ADDRESS>/` using the VM's reported address. 
This opens a port in the guest firewall; it does not forward the service to your Mac's `localhost`.

## Keep the module self-contained

- Put imported files and configuration templates inside the chosen directory. Relative Nix paths refer to the file containing them.
- Avoid imports that reach outside the directory, such as `../shared.nix`. Limanix copies only the selected tree, then evaluates that copy in the guest.
- Use regular files and directories. Symbolic links and special files inside the tree are not copied; `default.nix` must be a regular file.
- Keep the tree small. The copy includes all its files, including hidden files; do not use the whole project or a checkout containing `.git` as the module tree.

Your imported module does not need `module.toml` or a `flake.nix`. 
Catalog metadata is a separate convention explained in [Contribute to the catalog](contributing.md).
`nixos.modules` accepts identifiers, not a `.nix` filename, a glob, or a Git URL.

## Work with the guest account

To add packages to Limanix's configured guest user's environment, use the `runtime` argument rather than hard-coding `dev`:

```nix
{ pkgs, runtime, ... }:
{
  users.users.${runtime.user.name}.packages = [ pkgs.jq ];
}
```

Limanix supplies `runtime.user.name` from its VM configuration. 
This argument is specific to Limanix; a standalone NixOS configuration must provide its own equivalent.

Prefer TOML for the settings Limanix already manages: VM resources, user identity, mounts, environment values, and exposed ports. 
Use your module for packages and services. 
A module can conflict with the guest base; the client does not prevent arbitrary overrides of NixOS options.

```{important}
Use trusted module code. 
Modules can configure privileged services inside the guest, which may also have access to directories shared from your Mac.
Keep passwords and tokens out of Nix source and generated Nix files: they can end up in the Nix store. 
See {ref}`Source files and the Nix store <module-nix-store>`.
```

Continue with [Build reusable modules](reusable-modules.md) to share configurable behavior across projects.
