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
| Personal state | User configuration and local state under `~/.codex/` by default; credential storage follows Codex settings |
| Integration | Works in the project's guest directory; select the tools your project needs separately |
| Services and capabilities | No daemon or language-support declarations |

Personal defaults live in `~/.codex/config.toml`. Trusted projects can also use
`.codex/config.toml`; see
[configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic).

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Authentication | Run `codex login status` inside the guest; the module does not copy host credentials |
| Device-code login is unavailable | Check account permissions or use another method in the authentication guide |
| Project command is missing | Select the required language or tool module; Codex does not install the project's toolchain |
| Update notice | Codex checks for new releases at startup; a newer version arrives with a catalog release, not through npm or Homebrew. To hide the notice, set `check_for_update_on_startup = false` in `~/.codex/config.toml` |
| Sandbox or account access | Native checks cover offline CLI startup and help; authenticated requests and sandbox execution in a VM are not covered |

## Guarantees

|
