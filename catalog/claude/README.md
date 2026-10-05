# Claude Code

Installs `claude`, Anthropic's terminal coding agent.

```toml
[nixos]
modules = ["lmx:claude"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Claude Code comes from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Inside the VM, `claude --version` shows the
installed version. A newer version arrives with a catalog release; the module
turns off Claude Code's own updates.

## Use

Start Claude Code from the project's guest directory:

```console
claude
```

Sign in through the prompts on first launch, or with `/login` inside a session.
See Anthropic's
[authentication guide](https://code.claude.com/docs/en/authentication) for
account and provider options.

Claude Code can read files, edit them and run local commands. See the
[setup guide](https://code.claude.com/docs/en/setup) for requirements and
`claude doctor`.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native Claude Code configuration; the module sets no model, permission or sandbox preferences |
| Personal state | `~/.claude/` and `~/.claude.json` by default; `CLAUDE_CONFIG_DIR` moves the configuration directory |
| Project settings | Shared `.claude/settings.json` and personal `.claude/settings.local.json`; see [settings files](https://code.claude.com/docs/en/settings#settings-files-and-who-they-affect) |
| Updates | `DISABLE_UPDATES=1` in every session turns off background and manual updates; see [disable auto-updates](https://code.claude.com/docs/en/setup#disable-auto-updates) |
| Unfree package | The module adds `claude-code` to `nixpkgs.config.allowUnfreePackages` |
| Services and capabilities | No daemon or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Authentication | Sign in inside the guest; the module does not copy host credentials |
| Network | Claude Code needs internet access from the guest; see the [system requirements](https://code.claude.com/docs/en/setup#system-requirements) |
| `claude update` or `claude install` | Refused; a separate copy under `~/.local` would bypass the catalog version and update itself |
| Local build | Unfree packages are not in the NixOS binary cache; the module permits building the package, which wraps and patches Anthropic's downloaded binary |
| Project command is missing | Select the required language or tool module; Claude Code does not install the project's toolchain |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Installs the base Nixpkgs Claude Code package | `eval.package` |
| Declares unfree permission for Claude Code | `eval.unfreeDeclaration` |
| Turns off background and manual updates in every session | `eval.updatesDisabled` |
| The system-profile command prints its version and offline help | `run.commands` |
