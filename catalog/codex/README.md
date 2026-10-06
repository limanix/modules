# Codex CLI

Installs `codex`, OpenAI's terminal coding agent.

```toml
[nixos]
modules = ["lmx:codex"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Codex comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `codex --version` shows the
installed version.

## Use

Authenticate inside the VM:

```console
codex login --device-auth
codex login status
```

Enable device-code login in your ChatGPT security settings or workspace
permissions first. Open the printed link in your Mac's browser and enter the
one-time code. API-key authentication is also supported; API usage is billed
separately. See the [authentication guide](https://learn.chatgpt.com/docs/auth).

Run the interactive agent from the project's guest directory:

```console
codex
```

Codex can inspect files, edit them and run local commands. `codex exec --help`
describes non-interactive use. See the
[CLI guide](https://learn.chatgpt.com/docs/codex/cli).

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native Codex configuration; the module sets no model, approval or sandbox preferences |
| Personal state | User configuration and local state under `~/.codex/` by default; credential storage follows Codex settings; see [Keep state across VMs](#keep-state-across-vms) |
| Integration | Works in the project's guest directory; select the tools your project needs separately |
| Services and capabilities | No daemon or language-support declarations |

Personal defaults live in `~/.codex/config.toml`. Trusted projects can also use
`.codex/config.toml`; see
[configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic).

### Keep state across VMs

Codex keeps its configuration, file-based sign-in, sessions for `codex resume`,
prompt history and logs under `~/.codex/`. The managed home keeps them while the
VM exists; a recreated VM gets a new managed home and starts without them. To
keep them on your Mac, mount a Mac directory there:

```toml
[[mounts]]
source = "~/.limanix/agents/dev-box/codex"
target = "/home/dev/.codex"
mode = "rw"
```

Use your `user.home` in place of `/home/dev` and create the Mac directory before
`create` or `update`; see
[Share project directories](https://limanix.dev/categories/client/configuration.html#share-project-directories).
To use another guest path, set `CODEX_HOME` in the `[env]` table.

- Give each VM a directory of its own. Two VMs writing the same directory at the
  same time can overwrite each other's state.
- Do not mount your Mac's `~/.codex`: its configuration can name Mac paths and
  tools that do not exist in Linux.
- `codex resume` lists the sessions of the current repository. Mount the project
  at the same guest path in the new VM to find them.
- The directory holds the sign-in in `auth.json` when Codex stores credentials
  in a file, and plaintext history. Keep it out of repositories and synced
  folders.

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Authentication | Run `codex login status` inside the guest; the module does not copy host credentials |
| VM recreated | A new managed home starts without sign-in, sessions or history; [keep state across VMs](#keep-state-across-vms) on the Mac |
| Device-code login is unavailable | Check account permissions or use another method in the authentication guide |
| Project command is missing | Select the required language or tool module; Codex does not install the project's toolchain |
| Update notice | Codex checks for new releases at startup; a newer version arrives with a catalog release, not through npm or Homebrew. To hide the notice, set `check_for_update_on_startup = false` in `~/.codex/config.toml` |
| Sandbox or account access | Native checks cover offline CLI startup and help; authenticated requests and sandbox execution in a VM are not covered |

## Guarantees

|
