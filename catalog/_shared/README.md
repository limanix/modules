# Shared helpers

Schemas, package sources and test helpers for catalog modules. Keep module
policy in the module; the [catalog contract](../README.md) defines the rules.

Every system loads root `*.nix` schemas except `test.nix`, the shared test
export. Import helpers from `lib/` and `test/` explicitly.

## Find what you need

| Task | Helper |
| -- | -- |
| Check configuration and installed packages | [test/helpers.nix](#check-a-configuration) |
| Check version lines | [test/lines.nix](#test-version-lines) |
| Define a versioned toolchain | [lib/toolchain.nix and test/toolchain.nix](#define-a-toolchain) |
| Use system-profile headers and libraries | [lib/compiler.nix](#build-against-the-system-profile) |
| Check executable selection | [test/profile-commands.nix](#check-profile-commands) |
| Use another Nixpkgs revision | [lmx.pins and pinned](#use-another-nixpkgs-revision) |
| Resolve releases or a package source | [lib/release.nix and lib/source.nix](#resolve-a-version-line) |
| Provide language tools and parsers | [languageSupport](#share-language-tools) |
| Apply theme colors | [theme](#theme-colors) |
| Add shell colors or prompt status | [Shell helpers](#colors-in-shell-code) |
| Test terminal programs or language servers | [Process helpers](#drive-processes) |

## Check a configuration

[test/helpers.nix](test/helpers.nix) evaluates module entries and checks their
configuration:

```nix
{ evalSystem, pkgs, lib }:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
in
{
  eval.package = helpers.installed configuration pkgs.gh;
  run.commands = import ./test/run.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
  };
}
```

| Helper | Result |
| -- | -- |
| `evaluate modules` | `{ config; pkgs; lib; }` |
| `installed configuration package` | Whether the package is in `systemPackages` |
| `installedAsDeclared configuration package` | Also checks the declared priority |
| `selectedPackage configuration package` | Whether it wins over packages with the same identity (`pname`, otherwise `name`) |
| `packagePriority package` | `meta.priority`, or the Nixpkgs default |
| `profileFor configuration` | `config.system.path`, for execution checks |
| `sourceFor configuration source` | `{ packages; pins; }`, using the system's pins and unfree permissions |
| `verify label value configuration` | `true`, or an error naming `label` |

`verify` requires Boolean `true`. Running the profile checks commands, not
system activation.

## Test version lines

[test/lines.nix](test/lines.nix) evaluates each declared line and calls your
callbacks:

```nix
lineTests = import ../../_shared/test/lines.nix {
  inherit evalSystem pkgs lib;
  moduleDirectory = ./.;
  checkLine = { line, configuration }: import ./test/check.nix { inherit line configuration; };
  runLine = { line, configuration }: import ./test/smoke.nix { inherit line configuration; };
};
```

`checkLine` returns a Boolean; optional `runLine` returns a derivation. Export
`inherit (lineTests) eval run;` for `eval."line-<line>"` and
`run."commands-<line>"`. Test coexistence separately, for example in
`eval.allLines` or `fails.twoLines`.

<details>
<summary>Other results and laziness</summary>

| Result | Value |
| -- | -- |
| `lines` | Lines in numeric order, such as `1.9`, `1.10` |
| `metadata` | Parsed `module.toml` |
| `configurations.<line>` | Configuration for `versions/<line>.nix` |
| `defaultConfiguration` | Configuration for `default.nix` |
| `allConfiguration` | Configuration importing all lines |

Reading `lines` or `metadata` evaluates no system. Configurations are evaluated
once and shared by callbacks.

</details>

## Define a toolchain

[lib/lines.nix](lib/lines.nix) handles version selection, packages, end-of-life
warnings and help cards. Supply a module spec, as PostgreSQL does:

```nix
# default.nix
import ../../_shared/lib/lines.nix (import ./lines.nix)
```

```nix
# module.nix
version: {
  imports = [ ./default.nix ];
  lmx.internal.postgres.versions = [ version ];
}
```

```nix
# versions/18.nix
import ../module.nix "18"
```

| Spec field | Meaning |
| -- | -- |
| `name`, `title`, `directory`, `page` | Module name, product title, directory and page under `docs.limanix.dev` |
| `main` | Package attribute whose version names the line, such as `"go"` |
| `packages` | Function resolving a line's packages |
| `line` | Configuration callback receiving `{ version, tools, rank, priority, config, lib, pkgs }` |
| `commands`, `versioned`, `tips` | Commands, per-line command names and help tips |
| `single` | Require one selected line |
| `priorityOffset` | Lower package priorities by this amount |
| `product`, `extra` | Product name in warnings; configuration outside a line |

[lib/toolchain.nix](lib/toolchain.nix) adds editor support. `tool`, `parsers`,
`provider` and `systemPackages` describe the tool identity, parsers, provider
record and installed packages. The newest selected line recommends its server;
`providerPriority` can override the recommendation's default base priority.

[test/toolchain.nix](test/toolchain.nix) exports:

| Group | Checks |
| -- | -- |
| `eval` | `line-<line>`, `allLines`, `userOverride` |
| `run` | `commands-<line>`, `languageServer`, `userOverride`, `allLines` |

The module supplies `commands`, `coexisting` package attributes and
`profileCommands`, plus any extra `eval` checks and `builds`.

## Build against the system profile

[lib/compiler.nix](lib/compiler.nix) wraps a Nixpkgs compiler with fallback
paths: `/run/current-system/sw/include` after compiler and libc headers, and
`/run/current-system/sw/lib` after command-line library paths and last in
dynamic `RUNPATH`. Pass `prefix` to use another profile in tests.

```nix
gcc = import ../../_shared/lib/compiler.nix { compiler = packages.gcc15; };
```

The compiler module adds `/include` to `environment.pathsToLink` and `dev`,
`out`, `lib` to `environment.extraOutputsToInstall`. This matters for packages
such as OpenSSL: NixOS otherwise installs only `bin` and `man` when a `bin`
output exists, leaving libraries out.

## Check profile commands

[test/profile-commands.nix](test/profile-commands.nix) checks which executable
wins when several lines supply a command:

```nix
run.newestCommand = import ../../_shared/test/profile-commands.nix {
  inherit pkgs;
  profile = helpers.profileFor lineTests.allConfiguration;
  expectedCommands.go = "${newestGo}/bin/go";
};
```

The test platform sorts packages by store path, then priority. Resolve command
collisions with explicit priorities (`lib.setPrio`), never import order.

## Use another Nixpkgs revision

Declare a revision and hash in `lmx.pins`, then use the `pinned` argument:

```nix
{ pinned, ... }:
{
  lmx.pins."<revision>" = "<sha256>";
  environment.systemPackages = [ pinned."<revision>".go_1_22 ];
}
```

- Pins are plain constants, without `mkDefault` or `mkForce`. Different hashes
  for one revision fail evaluation.
- Use `pinned` in configuration values, never `imports` or option declarations.
- List unfree package names in `nixpkgs.config.allowUnfreePackages`.
- `unstableSource` exposes `rev` and `sha256` from
  [unstable.toml](unstable.toml). Platforms declare its pin before reading
  `pinned.${unstableSource.rev}`; modules use `lib/source.nix` instead.

Each revision is imported lazily once per system, without overlays, and follows
the unfree list using its own `lib.getName`. Unused revisions are not fetched. A
pin does not guarantee a cache hit or authorize a
[local build](../README.md#local-builds-and-runtime).

## Resolve a version line

For version lines from Nixpkgs, `releases.nix` maps each declared line to a
record:

```nix
{
  "1.27" = { source = "base"; package = "go_1_27"; endOfLife = false; };
  "1.28" = { source = "unstable"; package = "go_1_28"; endOfLife = false; };
  "1.25" = {
    source = { rev = "<revision>"; sha256 = "<sha256>"; };
    package = "go_1_25";
    version = "1.25.13";
    endOfLife = true;
  };
}
```

| Source | Package set | Version check |
| -- | -- | -- |
| `"base"` | System `pkgs`, from `flake.lock` | Selected line (`1.27` accepts `1.27.x`) |
| `"unstable"` | [unstable.toml](unstable.toml) revision | Selected line |
| `{ rev, sha256 }` | Pinned snapshot | Exact `version` |

[lib/release.nix](lib/release.nix) returns the record with `packages`, `pins`,
`matches` and `resolve`:

```nix
{ version, pinned, pkgs }:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  go = release.packages.${release.package};
in
assert release.matches go.version;
{ inherit go; }
```

Declare `release.pins` in `lmx.pins`; reading them evaluates no package set.
Other record fields remain available; `release.resolve` resolves an additional
source, such as a separately pinned compiler.

For a module without lines, use [lib/source.nix](lib/source.nix) directly:

```nix
{ pkgs, pinned, ... }:
let
  unstable = import ../../_shared/lib/source.nix {
    source = "unstable";
    inherit pkgs pinned;
  };
in
{
  lmx.pins = unstable.pins;
  environment.systemPackages = [ unstable.packages.claude-code ];
}
```

Base and unstable follow patch updates without a `version` field; snapshots
require one and stay fixed. The weekly update flow checks both moving pins and
opens a PR when either changes. The resolver validates `source`, `package`,
`endOfLife` (`true`, `false` or `null`) and the version rule; the harness checks
that records match the lines in `module.toml`.

## Share language tools

Providers publish tool records and parsers in
`lmx.capabilities.languageSupport`; editors consume the result:

```nix
lmx.capabilities.languageSupport = {
  languages.go.parsers = [ "go" "gomod" ];
  tools.gopls = lib.mkOverride (1000 - rank) {
    package = tools.gopls;
    command = "${tools.gopls}/bin/gopls";
    languages = [ "go" ];
  };
};
```

- Tool records merge as a whole. The strongest priority wins; equal records at
  the same priority agree, different records fail.
- `rank` counts declared lines older than the selection, with `0 <= rank < 100`.
  The helper uses `(spec.providerPriority or 1000) - rank`; a user definition or
  `mkForce` overrides the recommendation. Name tools by executable identity,
  such as `gopls`, rather than module name.
- Providers install the winning `package`; consumers use its `command` and
  `args`.
- Parser lists merge without duplicates and do not require a tool.

| Field | Type |
| -- | -- |
| `tools.<identity>.package` | Package; required |
| `tools.<identity>.command` | String (executable); required |
| `tools.<identity>.args` | String list; default `[]` |
| `tools.<identity>.languages` | Language-name list; default `[]` |
| `languages.<language>.parsers` | Parser-name list; default `[]` |

## Drive processes

[test/terminal.py](test/terminal.py) runs commands in a pseudo-terminal with
timeouts and bounded output. In a module's `test/run.nix`, add
`PYTHONPATH = ../../../_shared/test;` to the `runCommand` environment:

```python
from terminal import TerminalProcess

with TerminalProcess([program], env=environment) as process:
    process.until(lambda: b"ready" in process.output, timeout=5)
    process.send(b"q")
```

[test/lsp-smoke.py](test/lsp-smoke.py) checks language-server initialization and
shutdown:

```sh
python ${../../../_shared/test/lsp-smoke.py} --timeout 10 ${profile}/bin/gopls
```

## Theme colors

Read `lmx.capabilities.theme` in configuration values:

```nix
{ config, ... }:
let
  inherit (config.lmx.capabilities.theme) name palette colors dark;
in
{
  # system: colors.accent == 5 (terminal magenta)
  # tokyo-night: colors.accent == palette.accent == "#7aa2f7"
}
```

| Field | Value |
| -- | -- |
| `name` | `system` (default) or a table name from [themes.toml](themes.toml); chosen by the user, not modules |
| `palette` | 18 role colors as `#rrggbb`; Catppuccin Mocha under `system` for explicit-color tools |
| `dark` | Whether the palette uses a dark background |
| `ansi` | Role mapping from [ansi.toml](ansi.toml): indices `0..15`, or `null` for terminal defaults |
| `colors` | `ansi` under `system`, otherwise `palette` |

All fields except `name` are read-only. Equal `name` definitions agree;
conflicting definitions at the same priority fail. Under `system`, leave
backgrounds to the terminal so colors follow the Mac terminal's theme.

| Role | Use |
| -- | -- |
| `background` | Main background |
| `background_dark` | Darker panels and bars |
| `background_darker` | Deepest background |
| `surface` | Raised elements: current line, menu, message |
| `selection` | Selected text and items |
| `border` | Borders, separators, inactive outlines |
| `muted` | Comments, hints, disabled text |
| `subtle` | Secondary text and labels |
| `foreground` | Main text |
| `accent` | Focus, active items, highlights |
| `red`, `orange`, `yellow`, `green`, `cyan`, `blue`, `purple`, `pink` | Hues: red for errors, yellow for warnings, green for success, blue for information |

To add a theme, provide `title`, `homepage`, `dark` and all roles in
[themes.toml](themes.toml). Take colors from its Neovim colorscheme in locked
Nixpkgs and its published palette; name those sources in a comment. Choose the
nearest source color for a missing role. Update the theme-set expectations in
[theme-tests.nix](test/theme-tests.nix); the tests also compare Catppuccin Mocha
with `pkgs.catppuccin`. See [theme integration](../README.md#colors-and-themes)
for previews and module checks.

## Colors in shell code

[lib/sgr.nix](lib/sgr.nix) encodes a foreground color: `"34"` for terminal blue,
`"38;2;122;162;247"` for a palette color, `"39"` for the terminal default.

```nix
blue = import ../../_shared/lib/sgr.nix lib config.lmx.capabilities.theme.colors.blue;
prompt = ''\[\e[${blue}m\]\w\[\e[0m\] '';
```

[lib/status-words.nix](lib/status-words.nix) supplies `bash` and `zsh` code that
refreshes `LMX_STATUS_WORDS` from `lmx status --short`, empty inside tmux.
Source it after prompt initialization when the prompt displays an environment
variable instead of running its own status command.

[test/prompt-smoke.nix](test/prompt-smoke.nix) runs prompt initialization and a
check script in interactive Bash or Zsh without user startup files.

## Change `_shared`

Add shared code only when several modules need it. Keep named-module policy,
version choices and module-specific tests outside `_shared`. Root `.nix` schemas
are loaded automatically, except the `test.nix` export; put pure functions in
`lib/` and test helpers in `test/`.

Add tests in [\_shared/test.nix](test.nix). A change here makes CI check the
whole catalog.
