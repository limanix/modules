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
| Personal state | `~/.claude/` and `~/.claude.json` by default; `CLAUDE_CONFIG_DIR` moves both into one directory; see [Keep state across VMs](#keep-state-across-vms) |
| Project settings | Shared `.claude/settings.json` and personal `.claude/settings.local.json`; see [settings files](https://code.claude.com/docs/en/settings#settings-files-and-who-they-affect) |
| Updates | `DISABLE_UPDATES=1` in every session turns off background and manual updates; see [disable auto-updates](https://code.claude.com/docs/en/setup#disable-auto-updates) |
| Unfree package | The module adds `claude-code` to `nixpkgs.config.allowUnfreePackages` |
| Services and capabilities | No daemon or language-support declarations |

### Keep state across VMs

Claude Code keeps its sign-in, settings, session transcripts for
`claude --continue` and `claude --resume`, prompt history and auto memory in its
configuration directory. The managed home keeps them while the VM exists; a
recreated VM gets a new managed home and starts without them. To keep them on
your Mac, mount a Mac directory and point `CLAUDE_CONFIG_DIR` at it. Claude Code
then also stores `.claude.json` there, so one mount holds all of its state:

```toml
[env]
CLAUDE_CONFIG_DIR = "/home/dev/.claude"

[[mounts]]
source = "~/.limanix/agents/dev-box/claude"
target = "/home/dev/.claude"
mode = "rw"
```

Use your `user.home` in place of `/home/dev`, add the variable to an existing
`[env]` table, and create the Mac directory before `create` or `update`; see
[Share project directories](https://limanix.dev/categories/client/configuration.html#share-project-directories).

- Give each VM a directory of its own. Two VMs writing the same directory at the
  same time can overwrite each other's `.claude.json`.
- Do not mount your Mac's `~/.claude`: macOS keeps the Claude Code sign-in in
  the Keychain, and Mac hooks and plugins may not run in Linux.
- Transcripts belong to the project's guest path. Mount the project at the same
  guest path in the new VM to resume its sessions.
- The directory holds the sign-in in `.credentials.json` and plaintext
  transcripts that can contain file contents and command output. Keep it out of
  repositories and synced folders.

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Authentication | Sign in inside the guest; the module does not copy host credentials |
| VM recreated | A new managed home starts without sign-in, sessions or memory; [keep state across VMs](#keep-state-across-vms) on the Mac |
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
