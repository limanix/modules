# Catalog contract

Module layout, public interfaces and checks for catalog authors. For setup, pull
requests and releases, see the
[contribution guide](https://docs.limanix.dev/contributing/).

## Add a module

Create `catalog/<kind>/<name>/` with these files:

| File | Purpose |
| -- | -- |
| `module.toml` | Description and optional version lines |
| `default.nix` | Default configuration and help card |
| `test.nix` | Behavior checks, including at least one `eval` check |
| `README.md` | Usage and public settings |

| Kind | Purpose | Selected through |
| -- | -- | -- |
| `shell` | Shell, editor, multiplexer and preset tools | `[shell]` |
| `toolchains` | Language compilers, runtimes and tools | `[toolchains]` |
| `modules` | Services and standalone tools | `[nixos] modules` |

The client owns shell presets and toolchain keys; only `modules` accepts user
selectors in `[nixos] modules`. `_shared` holds common schemas, data and
helpers. Other top-level directories are rejected.

Names must be unique across kinds, match `[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*` and
have at most 63 characters. `_shared`, `internal`, `capabilities` and `pins` are
reserved.

| `module.toml` field | Rule |
| -- | -- |
| `description` | Required nonempty string |
| `versions` | Optional list of unique lines matching `[0-9]+(\.[0-9]+)*`, each at most 63 characters |
| `default` | Required member of nonempty `versions`; absent otherwise |
| `prompt` | Optional, `shell` only: `shells` lists `bash`, `zsh` or both; see [Prompts](#prompts) |

Unknown fields are errors. Add `versions/<line>.nix` for each declared line.
Other implementation filenames are private; an optional `test/` directory can
hold test code and data.

From the repository root, replace `example` with your module name in
`task ci/catalog/modules MODULES=example`. Use `MODE=eval` for configuration and
expected-error checks only.

## Module boundaries

A module owns its packages, settings, tests and README; an aggregate owns its
component choices and integration tests. `_shared` provides generic helpers,
without policy for named modules.

Import other modules only through `default.nix` or a declared version entry. Use
their public options and shared capabilities, never private files, tests or
`lmx.internal.<name>`. Keep cross-module paths explicit: the CI planner cannot
follow fully computed paths.

| Options | Declared by | Use |
| -- | -- | -- |
| `limanix.*` | `interface.nix` | Account identity, shell, sessions and help cards |
| `lmx.<name>.*` | The named module | Documented public settings |
| `lmx.internal.<name>.*` | The named module | That module only |
| `lmx.capabilities.<area>.*` | Root `_shared/<area>.nix` | Typed data shared by providers and consumers |
| `lmx.pins` | `_shared/pins.nix` | Additional Nixpkgs revisions |
| Standard NixOS options | Nixpkgs | Normal NixOS settings |

The platform supplies account identity and shared schemas. Ownership applies to
declarations; modules may assign existing public options. Use defaults or
`lib.mkDefault` for settings users may replace, and assertions with clear
messages for required conditions. Resolve command collisions with explicit
package priorities, never import order or `mkBefore`.

Every public entry must declare `limanix.help.<name>`:

- Take `summary` from the metadata's `description`.
- List the commands added to `PATH`.
- Set `guide` to the module's page under `https://docs.limanix.dev/`.
- Use at most four tips, with labels of at most 10 characters.

The harness checks the guide prefix; reviewers check the page. See
[interface.nix](../interface.nix) for option types. A session command receives
one literal session name and returns status 64 for an invalid name. Language
providers use [shared capabilities](_shared/README.md#share-language-tools) and
must not enable an editor merely by offering tools.

## Colors and themes

Use [theme roles](_shared/README.md#theme-colors), not hardcoded themes or
colors. Draw with `colors.<role>`; use `palette.<role>` only when a tool needs
explicit colors under `system`. Otherwise, preserve terminal colors and
backgrounds under `system`. Keep settings user-overridable and document which
settings carry colors and how to replace them.

Reuse the [Catppuccin](_shared/lib/catppuccin.nix) and
[Textual](_shared/lib/textual.nix) adapters. Neovim may use a theme's own
colorscheme from [colorschemes.nix](shell/neovim/colorschemes.nix); otherwise it
draws the palette through catppuccin-nvim. Tools without system-wide color
settings keep their own colors; name these exceptions in the module README.

To add a theme:

1. Add its table to [themes.toml](_shared/themes.toml), following the
   [palette and source rules](_shared/README.md#theme-colors).
1. Add its Neovim colorscheme when Nixpkgs packages it.
1. Run `task generate/previews`, `task ci/catalog/layer` and the checks of the
   modules that read the theme:
   `task ci/catalog/modules MODULES="tmux lazygit yazi zsh cli-tools astronvim neovim harlequin posting"`.

## Prompts

A prompt is a `shell` component selected by `[shell] prompt`. Declare its
supported shells in `module.toml`; the client accepts it only with a compatible
preset:

```toml
description = "Example prompt in the guest's theme."

[prompt]
shells = ["bash", "zsh"]
```

- Set `programs.<shell>.promptInit` with `lib.mkDefault` for each declared
  shell. Do not change other startup settings or initialize undeclared shells.
- Use theme roles and symbols that work without Nerd Fonts or Powerline fonts.
- Show `lmx status --short` outside tmux; tmux's status line shows it inside.
  [Shell helpers](_shared/README.md#colors-in-shell-code) provide status and
  colors.
- Let personal settings take precedence and document their file.

Run `task generate/previews` after adding or changing a prompt.

## Version lines

`lmx:<name>` selects `default.nix`; `lmx:<name>-<line>` selects
`versions/<line>.nix`. Unknown modules and lines are errors. Both entries load
the same implementation; the default recommends the metadata's line with
`lib.mkDefault`. An explicit line must replace it in either import order.

Explicit lines must coexist as documented or fail with a clear assertion. Check
aliases and command priorities when lines coexist. See
[toolchain helpers](_shared/README.md#define-a-toolchain) and
[version tests](_shared/README.md#test-version-lines).

### Release maps

For version lines from Nixpkgs, `releases.nix` must cover exactly the lines in
`module.toml`. Follow the
[release record format](_shared/README.md#resolve-a-version-line): base and
unstable follow patch updates; snapshots require an exact version. `endOfLife`
is `true`, `false` or `null`.

### Package pins and unfree permissions

The base revision is in [flake.lock](../flake.lock); unstable is in
[unstable.toml](_shared/unstable.toml). For other revisions, follow
[pin declarations and usage](_shared/README.md#use-another-nixpkgs-revision).
Declare unfree package names as constants in
`nixpkgs.config.allowUnfreePackages`. Unfree permission does not authorize a
local build.

## Required checks for every module

The harness checks metadata, public entries, assertions, ownership, imports,
help cards and explicit-version precedence. The import graph does not cover
ordinary Nix `import` or `readFile`; review those separately.

The run phase verifies that help commands are executable in the profile's
`bin/`, without running them. Test the module's own behavior in `test.nix`,
which receives `{ evalSystem, pkgs, lib }`. `evalSystem modules` returns checked
configuration without building it; reuse configurations across related checks.
`pkgs` and `lib` come from the runner's base package set. See
[configuration helpers](_shared/README.md#check-a-configuration).

| Group | Required | Contents |
| -- | -- | -- |
| `eval` | Yes | Nonempty set of configuration checks; each returns Boolean `true` |
| `fails` | No | Records with exactly `modules` (NixOS module list) and `message` (nonempty string) |
| `run` | No | Test derivations for the runner's Linux system |
| `builds` | No | Exact derivations for that system allowed to build locally; permission only |

Optional groups default to `{}`; unknown groups fail. Test names match
`[a-z][A-Za-z0-9._-]*`. Names such as `packages`, `commands`, `line-<line>` and
`artifact` are conventions. Expected failures must match the intended
diagnostic; crashes and unrelated errors do not pass.

Test behavior and regressions at the cheapest sufficient level. Avoid repeating
NixOS merge tests and shared scenarios. Keep configuration and execution checks
where each protects a guarantee; remove obsolete tests. Fixtures must run
offline without personal host state, external services, VMs or
`system.build.toplevel`. These checks do not prove login or service and `/etc`
activation.

### Local builds and runtime

The dry-run plan allows selected tests, `preferLocalBuild = true` derivations
and exact entries in `builds`. Permissions include declarations from modules
imported by selected public entries, but not test-only imports. They do not
extend to dependencies or schedule another module's tests.

Other uncached builds fail before execution; a cache hit does not prove a new
execution. See the [build policy](../checks/build-plan.nix).

## Module README

Module READMEs become documentation pages from a published catalog release. Use
plain Markdown: headings, tables, fenced code and GitHub alerts. Keep file links
relative and site links absolute; the site maps links between module READMEs to
their pages.

Start with a description and `## Select`, then cover versions, use, public
settings, files, services, persistent state and corner cases where relevant.
Distinguish Mac and VM commands. Use simple English; omit generic test sections
that repeat this contract.

An optional `graph.toml` defines nodes with `name`, `text` and related ids in
`with`. Run `task generate/graph` after editing it to update
`catalog/graph.json`.

## Compatibility and CI

Follow the
[cross-repository release order](https://docs.limanix.dev/contributing/#changes-across-repositories)
for changes to selectors, metadata or public interfaces. Private layout and
version-line changes need no client change. Adding or removing lines and
changing the default require a catalog release. When removing a line, document
the migration and link to the previous release in release notes.

PR checks cover both Linux architectures and affected dependents. See the
[planner](../tools/harness/plan.py), [runner](../tools/harness/checks.py),
[cache](../tools/harness/cache.py) and
[PR workflow](../.github/workflows/pr.yml). The
[release workflow](../.github/workflows/release.yml) does not run module tests.
