# Catalog contract

Rules for catalog module authors, revision 6. NixOS combines modules into one
configuration. Nix evaluates that configuration; builds and system activation
are separate steps.

## Add a module

Create `catalog/<kind>/<name>/` with four files:

| File | Purpose |
| -- | -- |
| `module.toml` | Describe the module and any version lines |
| `default.nix` | Provide the module's default configuration and help card |
| `test.nix` | Check the module's own behavior; at least one `eval` check is required |
| `README.md` | Explain usage and public settings |

Choose the kind that matches how the client selects the module:

| Kind | Purpose | Selected through |
| -- | -- | -- |
| `shell` | Shell, editor, multiplexer and preset tools | `[shell]` |
| `toolchains` | Language compilers, runtimes and tools | `[toolchains]` |
| `modules` | Services and standalone tools | `[nixos] modules` |

The client owns shell presets and toolchain keys. Only the `modules` kind
accepts user selectors in `[nixos] modules`. All kinds follow the same ownership
and import rules. The catalog also has `_shared` for common schemas, data and
helpers. Other top-level directories are rejected.

Module names must be unique across kinds and match
`[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*`. Names have at most 63 characters. `_shared`,
`internal`, `capabilities` and `pins` are reserved.

| `module.toml` field | Rule |
| -- | -- |
| `description` | Required nonempty string |
| `versions` | Optional list of unique lines matching `[0-9]+(\.[0-9]+)*`, each at most 63 characters |
| `default` | Required member of nonempty `versions`; absent otherwise |

Unknown metadata fields are errors. A module without version lines needs only
`description`. Add a `versions/<line>.nix` entry for each declared line. The
`test/` directory is optional; use it when tests need separate files or data.
Other implementation filenames are private.

Run from the repository root, with your module name in place of `example`:

```sh
task ci/catalog/modules MODULES=example
```

This runs configuration and execution checks in a container. Use `MODE=eval` for
configuration and expected-error checks only. See
[development setup](../README.md#development) for Task and Docker requirements.

## Module boundaries

A module owns its packages, settings, tests and README. An aggregate owns its
component choices and their integration tests. `_shared` provides generic
helpers and does not contain policy for named modules.

Import another module through its `default.nix` or a declared version entry. Use
its documented public options and shared capabilities. Do not read its private
files, tests or `lmx.internal.<name>` values. Keep cross-module paths explicit;
the CI planner cannot follow fully computed paths.

| Options | Declared by | Use |
| -- | -- | -- |
| `limanix.*` | `interface.nix` | Account identity, shell, sessions and help cards |
| `lmx.<name>.*` | The named module | Documented public settings |
| `lmx.internal.<name>.*` | The named module | That module only |
| `lmx.capabilities.<area>.*` | Root `_shared/<area>.nix` | Typed data shared by providers and consumers |
| `lmx.pins` | `_shared/pins.nix` | Additional Nixpkgs revisions |
| Standard NixOS options | Nixpkgs | Normal NixOS settings |

The platform supplies the account name, home and shared schemas. Modules may set
existing public options; ownership checks apply to declarations. Use option
defaults or `lib.mkDefault` for settings that users may replace. Use an
assertion with a clear message for a required condition. Give packages that
provide the same command explicit package priorities. Import order and
`mkBefore` must not choose the winner.

Declare `limanix.help.<name>` for every public entry of your module:

- Use `description` from `module.toml` as `summary`.
- List the commands the module adds to `PATH`.
- Link `guide` to the module's page under `https://docs.limanix.dev/`.
- Use at most four tips, with labels no longer than 10 characters.

The harness checks the guide's address prefix; reviewers check the page itself.
See [interface.nix](../interface.nix) for option types and defaults. A session
command takes one literal session name and returns status 64 for an invalid
name. See [language tools](_shared/README.md#share-language-tools) and
[theme colors](_shared/README.md#theme-colors) when your module uses
capabilities. A tool provider must not enable an editor just by declaring its
tools.

## Version lines

`lmx:<name>` selects `default.nix`; `lmx:<name>-<line>` selects
`versions/<line>.nix`. Unknown modules and lines are errors. `default.nix` loads
the implementation and recommends the metadata's default line with
`lib.mkDefault`. An explicit entry uses the same implementation and selects its
line. Adding `default.nix` before or after it must not change the selected
line's result.

Several explicit lines must either work together as documented or fail with a
clear assertion. Do not drop a selection or choose a line through import order.
If lines coexist, check their aliases and the priority of ordinary commands. See
[toolchain helpers](_shared/README.md#define-a-toolchain) and
[version tests](_shared/README.md#test-version-lines) for examples.

### Release maps

Modules with version lines from Nixpkgs provide `releases.nix`. It must map
exactly the lines in `module.toml`. Each record declares `source`, `package` and
`endOfLife` (`true`, `false` or `null`). Base and unstable sources follow their
line without an exact version field. A snapshot `{ rev, sha256 }` requires an
exact `version`. See [release sources](_shared/README.md#resolve-a-version-line)
for the format and helpers.

### Package pins and unfree permissions

The base Nixpkgs revision comes from [flake.lock](../flake.lock). The shared
unstable revision comes from [\_shared/unstable.toml](_shared/unstable.toml).
Declare other revisions in `lmx.pins` and read them through the `pinned`
argument. Pins are plain constants, without priority overrides. Use `pinned` in
configuration values, never in `imports` or option declarations. Declare unfree
package names as constants in `nixpkgs.config.allowUnfreePackages`. Permission
to use an unfree package does not permit a local build. See
[using another revision](_shared/README.md#use-another-nixpkgs-revision) for
details.

## Required checks for every module

The harness checks metadata and each public entry's configuration, assertions,
option declarations, module imports and help card. For each version, it checks
that an explicit line replaces the default in either import order. The module
import graph cannot check ordinary Nix `import` and `readFile` expressions;
review them separately.

The run phase adds a `help-commands` check for each public entry. It checks that
the listed commands are executable in the system profile's `bin/`. It does not
run those commands or prove the module's own behavior. That behavior belongs in
`test.nix`, which the harness calls as:

```nix
import (moduleDirectory + "/test.nix") { inherit evalSystem pkgs lib; }
```

`evalSystem` takes a list of NixOS modules and returns their checked `config`
without building it. `pkgs` and `lib` are the runner's base packages and
library. Reuse a configuration across related checks. See
[configuration helpers](_shared/README.md#check-a-configuration) for an example.

| Group | Required | Contents |
| -- | -- | -- |
| `eval` | Yes | Nonempty set of configuration checks; each must return Boolean `true` |
| `fails` | No | Records containing exactly `modules` (a list of NixOS modules) and `message` (a nonempty string) |
| `run` | No | Test derivations for the runner's Linux system |
| `builds` | No | Exact derivations for that system allowed to build locally; permission only |

Optional groups default to `{}`; unknown groups fail. Test names must match
`[a-z][A-Za-z0-9._-]*`. Names such as `packages`, `commands`, `line-<line>` and
`artifact` are conventions, not extra requirements. A `fails` case must fail
with the expected diagnostic; a crash or unrelated error does not pass.

Test key module behavior and concrete regressions at the cheapest sufficient
level. Do not repeat NixOS merge tests or shared scenarios in every module.
Configuration and execution checks prove different things; keep both when
needed. Remove tests that no longer protect a required guarantee. Run fixtures
offline, without personal host state or external services. They must not use a
VM or `system.build.toplevel`. These checks do not prove NixOS login, service
activation or `/etc` activation.

### Local builds and runtime

Before running builds, the harness checks the dry-run plan. It allows only the
selected test derivations, derivations with `preferLocalBuild = true`, and exact
derivations listed in `builds`. The `builds` list also includes declarations
from modules imported by the selected public entries. Test-only imports do not
add permissions, and permission for a derivation does not cover its
dependencies. Reading another module's `builds` does not schedule its tests.
Other uncached builds fail before execution. A cached result does not prove a
new execution. See [build policy](../checks/build-plan.nix) for the
implementation.

## Module README

The module README is the source for its page on `docs.limanix.dev`. The site
reads all module READMEs from a published catalog release. Keep them in plain
Markdown: headings, tables, fenced code and GitHub alerts. Use relative links
for files in this repository and full URLs for the site. The site maps links
between module READMEs to its catalog pages.

Start with a short description and `## Select`, then explain versions and use.
Put settings, state and corner cases after the main examples. Say whether a
command runs on the Mac or inside the VM. Use simple English and keep details
about one module in its own README.

Explain what the module installs, how to select it and which settings users may
change. Describe multiple-line behavior, files, services, persistent data and
corner cases where relevant. Do not add a generic test section that repeats this
contract.

An optional `graph.toml` describes the module on the site's catalog graph. Each
node has `name`, `text` and related node ids in `with`. Run
`task generate/graph` after editing it.

## Compatibility and CI

Each client build bundles one catalog release and is tested with it. Changes to
selector grammar, metadata, public options, capabilities or the test interface
must ship with client support when they break compatibility. Private layout and
version-line changes need no client change. Adding or removing lines and
changing the default require a catalog release. When removing a line, explain
the migration and link to the previous release in release notes.

PR checks run on both Linux architectures and include affected dependent
modules. Scheduling, cache handling and reports are described in the
implementation: [planner](../tools/harness/plan.py),
[runner](../tools/harness/checks.py), [cache](../tools/harness/cache.py) and
[PR workflow](../.github/workflows/pr.yml). The
[release workflow](../.github/workflows/release.yml) does not run module tests.
