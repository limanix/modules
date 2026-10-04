# Shared catalog contracts

`_shared` provides application-independent schemas, data and test helpers. It
has no selector or module metadata. Each module owns its packages, source pins,
configuration and application scenarios.

| Path                            | Role                                                               | Loaded by                    |
| ------------------------------- | ------------------------------------------------------------------ | ---------------------------- |
| Root `*.nix`, except `test.nix` | NixOS schemas and infrastructure                                   | Every evaluated system       |
| `languageSupport.nix`           | Tool and language capability schema                                | Every evaluated system       |
| `pins.nix`                      | Module-declared source registry                                    | Every evaluated system       |
| `test.nix`                      | Shared infrastructure checks; the standard three-argument test ABI | Once per native architecture |
| `lib/`                          | Pure helpers                                                       | Explicit imports             |
| `test/`                         | Generic fixtures and test helpers                                  | Module-owned `test.nix`      |
| `palette.toml`                  | Common color data                                                  | Consumers that need it       |

See the [module contract](../../guides/catalog-contract.md). Shared code does
not name modules, choose their lines or reconstruct their private scenarios.

## Declared package sets

`lmx.pins` maps Nixpkgs revisions to content hashes. Modules supply ordinary
constant values. Do not apply `mkDefault`, `mkOverride` or `mkForce` to the
registry, an entry or an enclosing declaration. Equal ordinary hash declarations
for one revision agree; different ordinary hashes fail the string merge. The
schema retains standard NixOS priority handling; using these wrappers violates
the catalog contract. The registry contains no fixed revision or application
policy.

`pins.nix` supplies `_module.args.pinned`. Within one evaluated system,
`pinned.<revision>` is a shared lazy package set. An empty registry imports no
additional source. Inspecting its keys does not resolve its package sets.

| Input to `lib/pinned.nix` | Meaning                             |
| ------------------------- | ----------------------------------- |
| `sources`                 | Revision-to-hash attribute set      |
| `system`                  | Effective NixOS host platform       |
| `unfreePackages`          | Allowed package names; default `[]` |

Each imported value receives the supplied platform, `overlays = []` and unfree
policy. The policy reads that system's final
`nixpkgs.config.allowUnfreePackages` list and compares names using the imported
source's `lib.getName`. Separate evaluations keep separate registries and may
allow different names.

Use `pinned` only in configuration values. It cannot determine `imports` or the
structure of `options`, which resolve before module arguments. Declare unfree
names as constants. Let NixOS create the base package set from the final
configuration; do not supply a ready-made `nixpkgs.pkgs` that bypasses policy.
Source sharing does not guarantee a binary-cache hit. Unfree permission and
local-build permission are separate rules.

## Language support

`lmx.capabilities.languageSupport.tools.<identity>` declares one complete tool:

| Field       | Type                          | Meaning                          |
| ----------- | ----------------------------- | -------------------------------- |
| `package`   | package, required             | Package supplying the executable |
| `command`   | string, required              | Executable to launch             |
| `args`      | list of strings; default `[]` | Arguments                        |
| `languages` | list of strings; default `[]` | Language identities              |

A tool key identifies the tool independently of provider modules and versions.
Providers apply `lib.mkOverride (1000 - rank)` to the complete record, with
`0 <= rank < 100`. Ordinary user declarations and `mkForce` are stronger.

The schema fills optional defaults before comparing equal-priority records.
Equal records agree; different records fail. A stronger record replaces all
fields, including optional values. Providers install the selected package;
consumers map its command and arguments to their own application settings.

`lmx.capabilities.languageSupport.languages.<language>.parsers` is a required
list. Contributions add and deduplicate. Parser declarations do not require a
tool. Empty schemas install no application.

## Version-line fixtures

Import [test/lines.nix](test/lines.nix) from a module's public `test.nix`:

```nix
lineTests = import ../_shared/test/lines.nix {
  inherit evalSystem pkgs lib;
  moduleDirectory = ./.;
  checkLine = import ./test/check-line.nix;
  runLine = import ./test/commands.nix;
};
```

The example callbacks are functions owned by the module. `checkLine` is required
and must return a Boolean. `runLine` is optional; its default is `null`. Each
callback receives the numeric line string and a record `{ config; pkgs; lib; }`.
`config` comes from `evalSystem` of that line's public entry point. The other
fields are the supplied native package set and library.

| Result                  | Value                                                  |
| ----------------------- | ------------------------------------------------------ |
| `metadata`              | Parsed module `module.toml`                            |
| `lines`                 | Numeric version order, for example `1.9`, `1.10`       |
| `configurations.<line>` | Lazy record for `versions/<line>.nix`                  |
| `defaultConfiguration`  | Separate lazy record for `default.nix`                 |
| `allConfiguration`      | Separate lazy record importing all public line entries |
| `eval."line-<line>"`    | Callback predicate; returns `true` or fails            |
| `run."commands-<line>"` | Callback derivation; absent when `runLine = null`      |

Reading metadata does not evaluate a system. Each demanded configuration is
shared by callbacks that use it. The helper does not export `allLines`, impose
coexistence or choose command priorities. A module exports its own combination
check or expected failure. Modules without numeric lines provide their own
nonempty `eval` checks.

## Native and VM foundations

[test/helpers.nix](test/helpers.nix) supplies `evaluate`, `profileFor`,
`verify`, `installed`, `installedAsDeclared`, `selectedPackage` and
`packagePriority`. Configuration records are `{ config; pkgs; lib; }`.
`verify label predicate configuration` accepts only a true Boolean. Profile
checks use the evaluated `config.system.path`; they do not prove activation.

A VM node imports [test/vm.nix](test/vm.nix) with optional `userName` and
`userHome`, plus the module's public entry point. Defaults are `dev` and
`/home/<userName>`. The wrapper uses [test/platform.nix](test/platform.nix) as
its single common foundation:

```text
module-owned VM node
  ├─ shared VM foundation
  │    ├─ interface.nix and discovered root schemas, excluding test.nix
  │    ├─ canonical systemPackages ordering
  │    └─ account following final limanix.user fields; UID 1000
  └─ module's public entry point and own activation assertions
```

The account uses the final configured name, home and shell rather than the
helper's default parameters. `system.stateVersion` follows the fixture's Nixpkgs
release. Each node gets packages from its effective NixOS policy. Import this
foundation into `runNixOSTest`, not into `evalSystem`, which already has a
platform. VM resources and application assertions remain in the module.

The production platform and VM foundation order packages after option merging:
`toString package`, then numeric package priority for identical paths. Sorting
preserves original records, contextual strings, duplicates and priorities. It
does not change `mkForce` or deduplicate user packages. Give colliding commands
explicit package priorities rather than relying on import order.

## Process helpers

[test/terminal.py](test/terminal.py) provides a bounded PTY process:

```python
from terminal import TerminalProcess

with TerminalProcess(argv, env=environment, cwd=directory) as process:
    process.until(lambda: b"ready" in process.output, timeout=5)
    process.send(b"input\n")
```

It keeps a bounded output tail and closes, terminates and reaps the process.
Callers own their application scenarios and deadlines. The helper also accepts
terminal `rows`, `columns` and `output_limit`.

[test/lsp-smoke.py](test/lsp-smoke.py) checks a server's initialize response and
shutdown over framed JSON-RPC. It handles unrelated messages and server
requests. Module-owned runtime checks supply the actual server command. Shared
unit checks use local fake processes and no network.

## Corner cases

| Case                                        | Result                                                    |
| ------------------------------------------- | --------------------------------------------------------- |
| Empty pin registry                          | No additional source import                               |
| Equal ordinary hashes for one revision      | One declaration                                           |
| Different ordinary hashes for one revision  | Evaluation error                                          |
| Inspecting unused pin names                 | Package sets remain lazy                                  |
| Equal-priority unequal tool records         | Evaluation error                                          |
| Stronger complete tool record               | All fields change together; omitted optional fields reset |
| Parser-only contribution                    | Accepted without a tool declaration                       |
| Metadata-only line inspection               | No `evalSystem` call                                      |
| Forbidden line combination                  | Module owns the diagnostic; helper does not hide it       |
| User changes VM identity                    | Fixture account follows final name, home and shell        |
| Contextual strings or `__toString` packages | Values and priorities survive canonical ordering          |

## Guarantees

`Checked by` names exact exports from the shared `test.nix`. Native fake-process
checks cover helper behavior; module checks cover integration with real tools.
Pin checks exercise the current loader's empty/lazy paths and argument wiring;
they do not download a source to prove architecture or unfree policy.

| Guarantee                                                                                | Checked by                                                                         |
| ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Empty language schemas contribute no tools or languages                                  | `eval.emptyCapabilities`                                                           |
| Optional tool defaults normalize before equality comparison                              | `eval.normalizedDeclarations`, `eval.equalDeclarations`                            |
| Tool records select atomically, including omitted optional fields                        | `eval.atomicDeclaration`                                                           |
| Parser contributions add and deduplicate independently of tools                          | `eval.parserContributions`                                                         |
| Unequal command, argument or language declarations fail                                  | `fails.conflictingCommands`, `fails.conflictingArgs`, `fails.conflictingLanguages` |
| Required tool fields and parser lists cannot be omitted                                  | `fails.missingToolCommand`, `fails.missingToolPackage`, `fails.missingParserList`  |
| Empty and unused pin values stay lazy in the actual loader                               | `eval.emptyPins`, `eval.lazyPins`                                                  |
| Equal ordinary pin hashes agree; different ordinary hashes fail                          | `eval.pinDeclarations`, `fails.conflictingPins`                                    |
| Empty registry reaches the actual `pinned` module argument                               | `eval.pinWiring`                                                                   |
| VM foundation loads public schemas, excludes test export and follows configured identity | `eval.vmPlatform`                                                                  |
| Package ordering preserves values, context, duplicates and replacement semantics         | `eval.canonicalPackages`, `eval.packageValues`                                     |
| Canonical profile retains the explicit package-priority winner                           | `run.packagePriority`                                                              |
| Lines sort numerically and callbacks receive their public entry records                  | `eval.numericLines`, `eval.lineCallbacks`                                          |
| Runtime callbacks produce named derivations without automatic realization                | `eval.lineRuntimeRecipes`                                                          |
| Metadata inspection stays lazy; default and all-line fixtures are separate               | `eval.lazyLineFixtures`, `eval.separateLineFixtures`                               |
| A non-Boolean line predicate fails                                                       | `eval.strictLinePredicate`                                                         |
| PTY deadlines, fragmented I/O, bounded output and cleanup work                           | `run.terminal`                                                                     |
| JSON-RPC framing, unrelated messages, failure diagnostics and cleanup work               | `run.protocol`                                                                     |
