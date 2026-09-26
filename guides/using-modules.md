---
myst:
  heading_anchors: 2
---

# Use catalog modules

Choose tools in a TOML file, create the VM, then use the tools inside it.
This guide starts with Git and Python and shows how to change the selection later.

## 1. Check the available modules

On your **Mac**, run:

```console
limanix modules list
```

Use identifiers from this list in `nixos.modules`.
The [catalog](catalog.md) links to each module's commands and examples.

## 2. Create a VM

Save this complete example as `limanix.toml` in an empty directory:

```toml
schema_version = 1
name = "module-lab"
env = {}
mounts = []

[resources]
arch = "arm64"
cpu = 2
mem = "4GiB"
disk = "16GiB"

[nixos]
modules = ["lmx:git", "lmx:python"]

[network.ports]
tcp = []
udp = []
```

Use `arch = "arm64"` on Apple Silicon and `arch = "amd64"` on an Intel Mac.
This example uses the default guest account, `dev`, with no project mounts or additional application ports.

On your **Mac**:

```console
limanix create --config limanix.toml
limanix shell module-lab
```

The first command creates and configures the VM.
The second opens a shell inside it.
The first build needs to download the base image and Nix dependencies.

Inside the **VM**:

```console
git --version
python -c 'print("Hello from the VM")'
```

Git prints its installed version, and Python prints `Hello from the VM`.
Your selected tools are ready to use in the guest.

## 3. Change the selection

Leave the guest shell with `exit`.
On your **Mac**, edit the existing `[nixos]` table in `limanix.toml` to add Neovim:

```toml
[nixos]
modules = ["lmx:git", "lmx:python", "lmx:neovim"]
```

Keep the modules you still need in this list.
TOML allows only one `[nixos]` table.

```{warning}
Updating interrupts running work in the VM; see [Apply a configuration change](https://limanix.dev/categories/client/working-with-vms.html#apply-a-configuration-change).
```

Run on your **Mac**:

```console
limanix update --config limanix.toml
limanix shell module-lab -- nvim --version
```

The second command runs Neovim inside the VM and prints its version.
The `name` in the TOML file identifies the VM to update.

## Choose a specific version

For a project that needs Python 3.12, replace `lmx:python` in the existing selection:

```toml
[nixos]
modules = ["lmx:git", "lmx:python-3.12", "lmx:neovim"]
```

Run `limanix update --config limanix.toml` on your Mac to apply this change.
Check the [Python README](../catalog/python/README.md) for virtual environments and versioned commands.
The [Module catalog](catalog.md) explains defaults, version selectors, and using several versions together.

## Use language servers

Some modules include a language server for editors that support the Language Server Protocol (LSP).
For an editor running inside the VM, configure its LSP client to launch the server and open the project at its guest path.
The module READMEs name the servers and link to their editor setup instructions.
The modules do not configure editors, and selecting `lmx:neovim` does not enable LSP automatically.

```{note}
An editor running on your Mac does not automatically use the VM's language server.
Remote use requires editor-specific integration that connects to the server and handles the project paths on both systems.
Limanix does not provide that integration; sharing a project directory only shares its files.
```

## Share a project directory

The example starts with `mounts = []`.
To share the directory containing `limanix.toml`, remove that line and add:

```toml
[[mounts]]
source = "."
target = "/workspace"
mode = "rw"
```

Update the VM, open its shell, and run `cd /workspace`.
You can now edit files on your Mac and run your tools against the same files inside the VM.

| Mode | Guest access |
| --- | --- |
| `rw` | Read and change the files on your Mac |
| `ro` | Read the files without changing them |

```{warning}
With `rw`, deleting a file under `/workspace` inside the VM deletes that file on your Mac too.
```

To stop using a selection, see [Remove a module from a VM](https://limanix.dev/categories/client/modules.html#remove-a-module-from-a-vm).

For an import or update error, see [Troubleshooting](troubleshooting.md).
To add a tool outside the catalog, [write a module](writing-modules.md).
