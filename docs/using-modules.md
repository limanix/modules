# Use catalog modules

Choose the tools your VM needs, record the selection in TOML, then create or update the VM. 
The catalog already contains Git, Neovim, Docker, and several language toolchains.

## 1. See what your client includes

Run on your **Mac**:

```console
limanix modules list
```

The list includes bundled selectors and locally imported modules. 
Use `limanix modules list --json` when another tool needs machine-readable output.

The catalog is embedded in the client. 
Listing modules does not fetch the newest catalog from GitHub. 
Use a selector present in your installed client's list.

## 2. Create a small development VM

Save this complete example as `limanix.toml`:

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

Use `arch = "amd64"` on an Intel Mac. 
This example shares no project directories and opens no guest firewall ports. 
It uses the default guest account, `dev`.

On your **Mac**:

```console
limanix create --config limanix.toml
limanix shell module-lab
```

Inside the **VM**:

```console
git --version
python --version
```

The first creation needs the base image and Nix dependencies. 
Selecting a module applies its configuration during the guest build; no separate package installation command is needed.

## Defaults and version selectors

| Selection         | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `lmx:python`      | The Python default defined by the bundled catalog                       |
| `lmx:python-3.14` | The Python 3.14 line defined by that catalog                            |
| `lmx:git`         | An unversioned module; its package comes from the client's base Nixpkgs |

A selector such as `3.14` is a **toolchain line**, not an exact patch version.
The catalog pins the concrete package used for that selector. 
A later catalog can update its patch version or change an unqualified default.

For a project that needs a particular language line, choose its explicit selector:

```toml
[nixos]
modules = ["lmx:git", "lmx:python-3.14"]
```

See the [catalog reference](catalog.md) for the values in this source revision.
An explicit selector alone does not freeze all dependencies across future client and catalog releases.

## 3. Apply changes to an existing VM

Edit the existing `[nixos]` table; do not add a second table with the same name.
For example, add Neovim:

```toml
[nixos]
modules = ["lmx:git", "lmx:python-3.14", "lmx:neovim"]
```

Exit the guest shell and run on your **Mac**:

```console
limanix update --config limanix.toml
limanix shell module-lab -- nvim --version
```

```{important}
An update restarts the VM. Finish running work before applying it.
It preserves the VM disk and managed home, but a failed update does not automatically undo every change already applied.
```

Installing a newer client does not rewrite an existing VM by itself. 
Apply its selected catalog modules with `limanix update`.

## Keep more than one toolchain

Some catalog modules provide versioned commands for side-by-side use:

```toml
[nixos]
modules = ["lmx:python-3.12", "lmx:python-3.14"]
```

After updating, run inside the **VM**:

```console
python-3.12 --version
python-3.14 --version
virtualenv --python python-3.12 .venv
```

For these Python modules, the highest selected version supplies the ordinary `python` command. 
Use the versioned command when the project needs a specific one.
Go, Node.js, Rust, and Minikube also provide versioned commands; their details are in the [reference](catalog.md).

**Choose only one Docker version per VM.** Docker configures one system daemon; it is not a pair of independent language executables.

## Share project files

The initial example uses `mounts = []`. 
To work on a project, remove that line and add this table to the TOML file:

```toml
[[mounts]]
source = "."
target = "/workspace"
mode = "rw"
```

Here, `.` means the directory containing `limanix.toml`. 
After updating, enter the guest and run `cd /workspace`.

The mount exposes the same files to both systems. 
With `mode = "rw"`, changes and deletions inside the guest affect the project on your Mac. 
Use `mode = "ro"` when the guest only needs to read the files.

## Remove a selection

Remove its identifier from `nixos.modules`, then update the VM. 
To select no optional modules:

```toml
[nixos]
modules = []
```

The Limanix guest base remains. 
Removing a selection changes the system configuration; 
it is not a request to erase project files, virtual environments, container volumes, or other application data.

Need a package or service outside the catalog? 
Continue with [Write your first module](writing-modules.md).
