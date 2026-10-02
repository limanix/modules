# Console

`lmx:console` combines the configured terminal modules into a development environment.
Each component can also be selected separately.

| Component | Provides |
|---|---|
| [Zsh](../zsh/README.md) | Oh My Zsh, completion, suggestions, Starship, local Atuin history, zoxide and direnv |
| [tmux](../tmux/README.md) | Panes, sessions, clipboard integration and saved layouts |
| [AstroNvim](../astronvim/README.md) | Configured editor, language-server integration and Nix-built parsers |
| [CLI tools](../cli-tools/README.md) | Search, previews, Git diffs, structured data and system tools |
| [Lazygit](../lazygit/README.md) | Git terminal interface |
| [GitHub CLI](../gh/README.md) | GitHub repositories, pull requests and workflow runs |
| [Yazi](../yazi/README.md) | File manager |

## Select the module

```toml
[nixos]
modules = ["lmx:console", "lmx:go"]
```

Create or update the VM, then open a named tmux session from your Mac:

```console
limanix shell <name> --session dev
```

This creates `dev` or attaches to the existing session.
Its default shell is Zsh.
Inside the VM:

```sh
cd /workspace
nvim .
```

Use the actual mount path from your configuration if it differs from `/workspace`.
Start `lazygit`, `yazi` or `btop` in another tmux pane.
`Ctrl-b %` splits left/right, `Ctrl-b "` splits top/bottom, and `Ctrl-b d` detaches.
Run the same `limanix shell <name> --session dev` command on your Mac to reconnect.
The session keeps running after detaching or losing the connection while the VM stays up.
Inside AstroNvim, press Space and wait for the key hints.

Language toolchains remain separate selections.
[Go](../go/README.md) provides `gopls`; [Rust](../rust/README.md) provides `rust-analyzer`.
[Python](../python/README.md) provides Pyright; [Node.js](../nodejs/README.md) provides the JavaScript/TypeScript language server.
AstroNvim reads the language modules' NixOS declarations and enables their servers.
Console recommends the catalog's default AstroNvim line.
Add `lmx:astronvim-6` alongside Console to select the 6.x line explicitly.
See [AstroNvim versions](../astronvim/README.md#versions) for the scope of that pin.

For containers, add [Docker](../docker/README.md), which includes Lazydocker.
For the project workspace, HTTP and SQL clients, and a Compose playground, select [Cozy](../cozy/README.md).
For a local Kubernetes cluster, add [Minikube](../minikube/README.md), which includes K9s.
Console itself does not enable Docker or create a Kubernetes cluster.

## Configuration and state

The catalog release pins the shared configuration and package sources.
User history, tmux snapshots, editor state and GitHub credentials live in the VM user's home.
Updating the VM preserves those files.
The component pages explain supported customization.
The shell, tmux, AstroNvim, Yazi and Lazygit default to Catppuccin Mocha.

To change the login shell or disable the additional tmux navigation keys, select a custom module alongside Console:

```nix
{ pkgs, ... }:
{
  limanix.user.shell = pkgs.bashInteractive;
  lmx.tmux.navigation.enable = false;
}
```

This keeps the installed Console components and tmux's base configuration.
The Zsh integrations apply when running Zsh.
See [Write a module](../../guides/writing-modules.md#read-vm-user-settings) for the public account options.

Atuin starts with synchronization disabled.
Direnv requires `direnv allow` before loading a project's `.envrc`.
Git identity and GitHub authentication remain user configuration.

Tmux saves snapshots every 15 minutes while its server is running.
Before `limanix update`, use `Ctrl-b Ctrl-s` to save the current layout.
After the VM restarts, launch `tmux` to restore the saved session.
Restoration starts supported programs again; it does not resume interrupted builds or recover unsaved buffers.
See [tmux](../tmux/README.md) for the restoration controls.

For icons, select a Nerd Font in the terminal on your Mac.
The host terminal must support truecolor and OSC 52 for the configured clipboard flow.
Copying from a VM must be checked with that terminal; installing guest packages alone cannot enable host support.

## Composition

`lmx:console` uses ordinary Nix imports of the component modules.
Selecting a component alongside Console refers to the same module path and does not create a second configuration.
CI compares the resulting system derivations for both selections.
This requires a client that preserves the catalog source tree when preparing the VM.
Older clients that copy each module into an isolated directory cannot consume these imports.

## Versions

Console has no version lines.
Its component list belongs to the catalog release; versioned components recommend their catalog defaults.
Explicit supported selections follow each component's selection policy.

## Configuration and integration

| Boundary | Contract |
|---|---|
| Settings | Owned by the individual components; the aggregate declares no additional public options |
| Personal state | Guest home: shell history, editor state, tmux snapshots and application configuration |
| Integration | Imports the seven documented entry points; an explicit supported AstroNvim line replaces its recommendation |
| Services | Does not enable Docker or create a Kubernetes cluster |

## Corner cases

| Case | Behavior or next step |
|---|---|
| No language server | Select a language provider; Console does not choose project toolchains |
| Component selected twice | The shared entry point is imported once; supported public values remain the same |
| Conflicting component versions | Follow the component's selection policy; aggregate import order does not resolve conflicts |

## Guarantees

| Guarantee | Covered by |
|---|---|
| Imports the seven components listed above through their ordinary entry points | `components.nix`, `check.nix` |
| Repeating component imports preserves the system derivation and public option values | `tests.nix`: composition |
| The AstroNvim recommendation accepts an explicit supported line | `checks/integration.nix`: console.astronvimVersionSelection |
| Bash login-shell and disabled tmux-navigation overrides remain available | `checks/integration.nix`: console.shell, console.navigation |
| Component startup and integration behavior remains owned by its component | Component `check.nix` and `smoke.nix` checks |
