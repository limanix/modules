# Write a module

Start with a NixOS entry point that adds packages, then extend it with program
settings, services or native libraries. A project-local module can be imported
without catalog metadata or a flake. A catalog module also needs metadata, tests
and a README under the public contract. If you want to add it to this
repository, continue with [Add to the catalog](#add-to-the-catalog); that step
is optional.

[Concepts](concepts.md) explains the NixOS configuration model. This guide
introduces the Nix syntax through examples.

| Your task | Start here |
| -- | -- |
| Write a custom module | [Create a module](#create-a-module) |
| Add or maintain a catalog module | [Catalog contract](catalog-contract.md), then [Add to the catalog](#add-to-the-catalog) |
| Understand required tests | [Required checks](catalog-contract.md#required-checks-for-every-module) |

Keep module-owned packages, settings and tests in the module directory. Use
public entry points and capabilities when connecting modules; the
[catalog contract](catalog-contract.md#ownership) defines these boundaries.

## Create a module

Keep a project's modules in its repository, one directory per module:

```text
my-project/
└── modules/
    └── dev-tools/
        └── default.nix
```

Save this as `modules/dev-tools/default.nix`:

```{literalinclude} examples/dev-tools/default.nix
:language: nix
:linenos:
:name: custom-module-dev-tools
:class: code-example
```

The module adds `jq` and `ripgrep` to the VM. Download:
{download}`default.nix <examples/dev-tools/default.nix>`.

On your Mac, follow the client's
[Import a module](https://limanix.dev/categories/client/modules.html#import-a-module)
guide to register `modules/dev-tools/` as `dev-tools`, then select
`third-party:dev-tools` in `limanix.toml` and create or update the VM. After
editing the source, replace the imported copy and update the VM as described in
[Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module).

### Read the module

The file describes the desired configuration, not a sequence of installation
commands. Its assignment sets `environment.systemPackages`, the NixOS option
that lists packages to install for all users.

| Code | Meaning |
| -- | -- |
| [1](#custom-module-dev-tools.1){.external .code-lines} | A function that receives `pkgs` from NixOS; `...` accepts the other arguments it does not use |
| [2–7](#custom-module-dev-tools.2-7){.external .code-lines} | The function returns a set of settings, enclosed in braces |
| [3–6](#custom-module-dev-tools.3-6){.external .code-lines} | Assigns a list of packages to the option; list entries are separated with spaces, not commas, and the assignment ends with a semicolon |

`pkgs` is the package set supplied to the module. `pkgs.jq` selects the `jq`
package from it, and `pkgs.ripgrep` selects the package that provides the `rg`
command.

### Find packages and options

To adapt the module, look up the software or setting you need:

| Search | Use it for |
| -- | -- |
| [NixOS packages](https://search.nixos.org/packages) | Package attributes, such as `jq` to use as `pkgs.jq` |
| [NixOS options](https://search.nixos.org/options) | Option names, types, defaults, and examples |

In both searches, select the NixOS release that the catalog pins;
[NixOS version and package pins](concepts.md#nixos-version-and-package-pins)
names it. A package's attribute name can differ from its command, as with
`ripgrep` and `rg` above.

## Configure programs and services

Adding a package to `environment.systemPackages` makes its commands available,
but does not configure the program. Program and service options can handle that
setup as well as install the software. This module installs Neovim and makes it
the default editor:

```{code-block} nix
:linenos:
:name: custom-module-neovim
:class: code-example

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
```

| Code | Meaning |
| -- | -- |
| [2–5](#custom-module-neovim.2-5){.external .code-lines} | Groups Neovim's settings in a nested set |
| [3](#custom-module-neovim.3){.external .code-lines} | Enables Neovim with the Boolean value `true`; Boolean values have no quotes |
| [4](#custom-module-neovim.4){.external .code-lines} | Makes Neovim the default editor |

### Arguments and nested settings

The `defaultEditor` assignment above can also be written as
`programs.neovim.defaultEditor = true;`. The dots describe nested settings:
`defaultEditor` inside `neovim`, inside `programs`. The nested form is useful
when setting several options for one program.

This module needs no `{ pkgs, ... }:` header because it uses no arguments; the
first example needs `pkgs` to select packages. Modules can also request `lib`, a
library of helper functions, and `config`, the final configuration after all
modules are merged.

### Read VM user settings

LimaNix exposes the guest account through typed NixOS options. Read these
through `config` instead of hard-coding values such as the user name `dev`:

```nix
{ config, pkgs, ... }:
{
  users.users.${config.limanix.user.name}.packages = [ pkgs.jq ];
}
```

| Option | Type | Value |
| -- | -- | -- |
| `limanix.user.name` | string, read-only | Guest account name supplied by the client |
| `limanix.user.home` | string, read-only | Guest home directory supplied by the client |
| `limanix.user.shell` | shell package | Login shell; Bash by default, or Zsh with `lmx:zsh` |

The platform supplies `name` and `home` once. Modules read them; they do not
redeclare the account identity. For a module-owned VM test, select its account
through the
[fixture parameters](catalog-contract.md#shared-helpers-and-vm-tests).

These three options are declared in the shared `interface.nix` at the catalog
repository root, together with the
[session options](catalog-contract.md#option-classes-and-availability). The
client supplies the account identity and applies the selected shell to the
account. Modules that use these options depend on this interface rather than the
client's internal VM data layout. Their names, types and meanings form the
public contract; changing that contract requires a compatibility decision.

Select another login shell in a custom module:

```nix
{ pkgs, ... }:
{
  programs.fish.enable = true;
  limanix.user.shell = pkgs.fish;
}
```

This ordinary assignment overrides the Zsh module's `lib.mkDefault` value. Zsh
remains installed, and its shell integrations still apply to Zsh. Two modules
that offer different shells at the same priority still require an explicit
choice. Set `limanix.user.shell` rather than assigning the guest account's
`users.users.<name>.shell` directly.

### Migrate custom modules

The old `runtime` and `inputs` data are no longer available as module arguments.
Custom modules that read them need changes before their next VM create or
update. Migration errors from the generated flake link to this section. The
diagnostic does not restore their values. Catalog checks do not supply these
arguments or the temporary diagnostics. Remove these arguments from the module's
function signature and replace their uses as follows:

| Previous reference | Replacement |
| -- | -- |
| `runtime.name` | `config.networking.hostName`, the final hostname |
| `runtime.arch` | `pkgs.stdenv.hostPlatform`, the guest platform attribute set |
| `runtime.user.name` | `config.limanix.user.name` |
| `runtime.user.home` | `config.limanix.user.home` |
| `runtime.user.uid` | `config.users.users.${config.limanix.user.name}.uid` |
| `runtime.ports.tcp` | `config.networking.firewall.allowedTCPPorts` |
| `runtime.ports.udp` | `config.networking.firewall.allowedUDPPorts` |
| `runtime.user.sudo` | No public replacement |
| `runtime.modules` | Private client data; no replacement |
| `inputs` | Private root-flake inputs; no replacement |

`pkgs.stdenv.hostPlatform` is an attribute set, not the previous `"arm64"` or
`"amd64"` string. Its `system` field is `"aarch64-linux"` or `"x86_64-linux"`
for the supported guest architectures. Values read through `config` reflect the
final merged configuration, including changes from other modules. For example,
the firewall port lists can contain ports added by services as well as those
configured through the client.

Standard NixOS arguments such as `config`, `lib`, `pkgs` and `modulesPath`
remain available. The generated root flake imports the nixos-lima module itself;
module code does not receive the root flake's `inputs` set.

### Enable a service

Services work the same way. This module runs PostgreSQL and creates a database
and a database user named after the VM's user:

```{code-block} nix
:linenos:
:name: custom-module-postgresql
:class: code-example

{ config, ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ config.limanix.user.name ];
    ensureUsers = [
      {
        name = config.limanix.user.name;
        ensureDBOwnership = true;
      }
    ];
  };
}
```

| Code | Purpose |
| -- | -- |
| [1](#custom-module-postgresql.1){.external .code-lines} | Receives the [public account settings](#read-vm-user-settings) through `config` |
| [4](#custom-module-postgresql.4){.external .code-lines} | Enables the PostgreSQL service |
| [5](#custom-module-postgresql.5){.external .code-lines} | Creates a database named after the VM's user |
| [6–11](#custom-module-postgresql.6-11){.external .code-lines} | Creates a database user with the same name and makes it the owner of that database |

With this configuration applied, the matching guest user can connect to the
database with `psql` without a password. Each service documents its options,
including the ones it requires, in the
[option search](https://search.nixos.org/options). Keep passwords out of
modules; see [Trust and secrets](concepts.md#trust-and-secrets).

## Organize and combine modules

As a module grows, separate its concerns into files and decide which settings
other modules may override.

### Split a module into files

A larger module can import other files through its entry point:

```text
dev-tools/
├── default.nix
├── tools.nix
└── editor.nix
```

```nix
{
  imports = [ ./tools.nix ./editor.nix ];
}
```

Each imported file is a module of its own, such as the package list and the
Neovim example above. Paths are relative to the file that contains them. For
imported third-party modules, keep every imported file inside the module
directory to make it self-contained. Standard catalog modules may import
siblings, for example `imports = [ ../git/default.nix ];`. Use the explicit
entry-point file so Nix recognizes it as the same module when it is also
selected directly. The client preserves the whole catalog tree and imports only
the selected entry points. Nix then follows their imports. This lets an
aggregate such as `lmx:console` reuse the same modules that users select
individually.

Catalog composition, public options, and capability exchange follow the
[catalog contract](catalog-contract.md). The contract distinguishes repeat
imports from explicit version selection and defines who owns common
declarations.

`imports` combines modules. The Nix function `import ./file.nix` is different:
it evaluates a file and returns its value.

### Combine with other modules

NixOS merges your module with the rest of the system configuration:

| Definitions in different modules | Result |
| -- | -- |
| Lists, such as `environment.systemPackages` | Combined |
| Two different values for a string option, at the same priority | Evaluation fails with a `conflicting definition values` error |
| A value wrapped in `lib.mkDefault`, and an ordinary value | The ordinary value wins |
| A value wrapped in `lib.mkForce` | Replaces definitions with weaker priority, including ordinary values and `lib.mkDefault` |

Use `lib.mkDefault` for a value that other modules may replace:

```nix
{ lib, ... }:
{
  environment.variables.EXAMPLE_BUILD_MODE = lib.mkDefault "development";
}
```

Another module can then set `environment.variables.EXAMPLE_BUILD_MODE = "test";`
without a conflict. Changing the order of module imports does not resolve
conflicting option values. Use `lib.mkForce` for intentional replacement; for
list options, it replaces entire lists from weaker definitions. Definitions with
the same priority still merge or conflict.

When packages provide the same command, select its owner with an explicit
package priority. For example:

```nix
{ lib, pkgs, ... }:
{
  environment.systemPackages = [ (lib.hiPrio pkgs.netcat-openbsd) ];
}
```

The platform sorts final profile inputs by store path, then by ascending package
priority for identical paths. It preserves values, duplicates and user list
replacements. Do not rely on import order or `lib.mkBefore` to choose a command.
Package-file priority is separate from the option-definition priority used by
`mkDefault` and `mkForce`.

For modules with several lines, follow their documented command names and
selection policy. The contract does not require a particular suffix or the
newest ordinary command. Inside the VM, `readlink -f "$(command -v nc)"` shows
which package provides `nc`.

To give a module its own settings, such as an `enable` switch, see
[option declarations](https://nixos.org/manual/nixos/stable/#sec-option-declarations)
and
[conditional definitions with `mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals)
in the NixOS manual.

## Handle native dependencies

You may need more than a package list when a project's dependencies compile
native code or download Linux binaries. Package managers such as pip, npm, and
Cargo do not always provide the required system libraries or build tools. NixOS
keeps those dependencies under `/nix/store` instead of the conventional `/usr`
and `/lib` layout. Use the examples below for the problem you encounter; a
module does not need all of them.

| What fails | Typical message | See |
| -- | -- | -- |
| Building a dependency | `gcc: command not found`, `fatal error: zlib.h: No such file or directory`, or `No package 'openssl' found` | [Build tools and libraries](#build-tools-and-libraries) |
| Starting a downloaded program | `Could not start dynamically linked executable` | [Downloaded programs](#downloaded-programs) |
| Loading a native extension | `libstdc++.so.6: cannot open shared object file` | [Native extensions in Python and Node.js](#native-extensions-in-python-and-nodejs) |

### Build tools and libraries

This example adds a compiler, make, pkg-config, and the development files of two
libraries:

```{code-block} nix
:linenos:
:name: native-dependencies-build-tools
:class: code-example

{ lib, pkgs, ... }:
let
  # System libraries that your dependencies build against.
  libraries = with pkgs; [
    openssl
    zlib
  ];
  developmentPackages = map lib.getDev libraries;
in
{
  environment.systemPackages = [
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
  ]
  ++ developmentPackages;

  environment.variables.PKG_CONFIG_PATH = lib.concatMap (package: [
    "${package}/lib/pkgconfig"
    "${package}/share/pkgconfig"
  ]) developmentPackages;
}
```

| Code | Purpose |
| -- | -- |
| [8](#native-dependencies-build-tools.8){.external .code-lines} | Selects each library's development output, containing its headers and `.pc` files |
| [12–13](#native-dependencies-build-tools.12-13){.external .code-lines} | Provide GCC and make for builds that require them |
| [14](#native-dependencies-build-tools.14){.external .code-lines} | Adds pkg-config, which reports a library's compiler and linker flags |
| [18–21](#native-dependencies-build-tools.18-21){.external .code-lines} | Points pkg-config to those `.pc` files |

`let … in` names values used by the returned settings, and `with pkgs;` lets the
library list omit the `pkgs.` prefix. The `++` operator joins lists. Replace
`openssl` and `zlib` with the libraries your project needs. Keep only the build
tools it uses: the catalog's Go module already includes GCC, and Rust includes
GCC and pkg-config; Python and Node.js include no build tools. `node-gyp` also
needs Python, available from the [Python module](../catalog/python/README.md).

With the module applied, check inside the VM that pkg-config finds a library:

```console
pkg-config --cflags --libs openssl
```

The command prints compiler and linker flags with paths under `/nix/store`.
Build systems that query pkg-config use these flags automatically. The compiler
itself does not search the system profile for headers or libraries, so a build
that includes `zlib.h` without asking pkg-config still fails with
`No such file or directory`. Point the compiler to the library for that command
only:

```console
CPATH="$(pkg-config --variable=includedir zlib)" LIBRARY_PATH="$(pkg-config --variable=libdir zlib)" pip install .
```

Replace `zlib` with the missing library and `pip install .` with the failing
command. Both variables accept several directories separated by `:`. For a
library without `.pc` files, use its include and library directories under
`/nix/store` the same way. The Nix toolchain records runtime paths for libraries
passed to the linker; libraries loaded later can still need a search path, as
described below.

### Downloaded programs

Programs built for other Linux distributions may expect a loader under `/lib` or
`/lib64`. [nix-ld](https://github.com/nix-community/nix-ld) provides it at the
expected path:

```nix
{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Libraries that a program needs beyond the default set.
    ];
  };
}
```

The default library set includes the C++ runtime, zlib, OpenSSL, and curl;
`libraries` adds to it. Use this for glibc-based Linux binaries matching the
VM's architecture, including those downloaded by npm, pip, or test runners.

### Native extensions in Python and Node.js

Nixpkgs interpreters use their own loader and do not automatically use nix-ld's
library search path. If a compiled extension cannot find a library, pass the
nix-ld libraries to the affected command:

```console
LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" python -c "import numpy"
```

This requires nix-ld to be enabled. Replace the command with your own, such as
`python -m pytest` or `node server.js`. In a Python virtual environment,
activate the environment first.

```{warning}
Set `LD_LIBRARY_PATH` only for the command that needs it.
Setting it for the whole VM can make other programs load incompatible libraries.
```

The
[nix-ld documentation](https://github.com/nix-community/nix-ld/blob/2.0.6/README.md#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld)
explains this distinction.

### Other approaches

- Use a Nixpkgs package when the tool can use an installed program instead of
  downloading its own binary.
- Use
  [`python3.withPackages`](https://nixos.org/manual/nixpkgs/stable/#python.withpackages-function)
  for a Nixpkgs interpreter with its Python dependencies; this is separate from
  pip virtual environments.
- Run the tool in a supported Linux distribution's container with the
  [Docker module](../catalog/docker/README.md).

## Add to the catalog

A custom module can remain private to its project. To contribute it to the
catalog, place the [minimal example](#create-a-module) in `catalog/dev-tools/`
and add its public metadata, tests and README. Keep this order:

| Step | Result |
| -- | -- |
| Define the promise | A user action and expected result for the README |
| Write the entry point | Self-contained implementation behind `default.nix` |
| Add metadata | Discovery through `module.toml` |
| Export checks | Public `test.nix`, private fixtures under `test/` |
| Write the page | Selectors, settings, corner cases and exact guarantee keys |
| Validate | Selected `eval` and `run`; `vm.activation` when activation is promised |

```text
catalog/dev-tools/
├── default.nix
├── module.toml
├── test.nix
├── test/
│   └── commands.nix
└── README.md
```

For this entry, `module.toml` needs only a description:

```toml
description = "jq and ripgrep for inspecting project data."
```

It uses base packages and has no version lines. The public test entry checks
configuration and commands; its private implementation remains under `test/`.

### Write the result check

Save this as `catalog/dev-tools/test.nix`:

```nix
{ evalSystem, pkgs, lib }:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
in
{
  eval.packages = builtins.all (helpers.installed configuration) [
    pkgs.jq
    pkgs.ripgrep
  ];
  run.commands = import ./test/commands.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
  };
}
```

Save its native fixture as `catalog/dev-tools/test/commands.nix`:

```nix
{ pkgs, profile }:
pkgs.runCommand "dev-tools-commands" { nativeBuildInputs = [ profile ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  printf '{"ready":true}\n' | jq -e .ready
  printf 'module command check\n' > fixture.txt
  rg --fixed-strings 'module command check' fixture.txt
  touch "$out"
''
```

The fixture uses the evaluated system profile and temporary state. Merely
printing its derivation path does not run it. The harness calls only
`test.nix { evalSystem, pkgs, lib }`; it does not discover private check files.

| Export | Use it for |
| -- | -- |
| `eval` | Configuration properties; every value must be Boolean `true` |
| `fails` | Expected refusal with `modules` and a diagnostic `message` |
| `run` | Native command, wrapper, patch or integration behavior |
| `builds` | Exact artifact build permissions; not test evidence |
| `vm` | Real activation through `pkgs.testers.runNixOSTest` |

Choose the cheapest level that proves the promise. A configured value uses
`eval`; reading that value in a real application needs `run`; login, boot and
NixOS activation need `vm`. An incompatible public selection uses `fails` with
the module's own diagnostic.

Keep ordinary NixOS merge and upstream algorithm tests out of module fixtures.
Test the behavior your module adds. Reuse one evaluated configuration for
related assertions. Own integration scenarios can import dependencies' public
entry points, but cannot read their private packages or tests.

For private helpers, the
[shared API](catalog-contract.md#shared-helpers-and-vm-tests) offers
configuration records, installed-package predicates and lazy line fixtures. Do
not extend the public three-argument invocation with extra context.

### Follow the metadata rules

| Item | Rule |
| -- | -- |
| Directory name | Up to 63 characters; `[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*` |
| Reserved names | `_shared`, `internal`, `capabilities`, `pins` |
| Public files | `default.nix`, `module.toml`, `test.nix`, `README.md` |
| Metadata keys | Only `description`, `versions`, `default` |
| `description` | Nonempty string |
| `versions` | Optional unique numeric dotted strings, at most 63 characters each |
| `default` | A member of nonempty `versions`; absent for an unversioned entry |
| Version entries | `versions/<line>.nix` for every declared line |
| `README.md` | Contains a `## Guarantees` heading |

Each name segment begins with a letter. `dev-tools` is valid; `tools-2`,
`my_module` and `v3.14` as a version line are invalid. This makes the numeric
line suffix in `lmx:<name>-<line>` unambiguous.

Root `_shared/*.nix` declares generic schemas and infrastructure; the reserved
`_shared/test.nix` is its test export. Pure helpers use `_shared/lib/`, test
helpers use `_shared/test/`, and common data can use non-Nix files. The shared
layer knows no application names or private release pins.

### Write the entry's page

| Part | Content |
| -- | -- |
| Summary and selector | What the user gets and how to select it |
| Versions | Selectors, exact package versions, default and support status |
| Use | First commands and their expected result |
| Configuration and integration | Public options, dependencies, capabilities, files and services |
| Corner cases | Limitations, conflicting choices and persistent data |
| Guarantees | Observable promises linked to exact public tests |

For the example:

```markdown
## Guarantees

| Guarantee | Checked by |
| -- | -- |
| Installs jq and ripgrep | `eval.packages` |
| The selected system-profile commands process local input | `run.commands` |
```

Use existing `eval`, `fails`, `run` or `vm` keys. Build permissions are not
evidence; explain them separately when needed. Configuration does not prove
execution, and a native fixture does not prove login or NixOS activation. Avoid
a separate generic Tests section. Add the entry to [Catalog](catalog.md).

### Check the result

With Task and Docker installed, run from the repository root:

```console
task --yes ci/lint
task --yes ci/test/modules MODULES=dev-tools
```

`ci/test/modules` runs `eval`, then `run`. Omitting `MODULES` selects all
catalog modules. Names select whole modules, not private recipes or test
policies. Each selected module runs both stages in its own evaluator. CI uses
one module per job on each native architecture. The module's public export
defines its checks, including those of every declared line.

| Command | Coverage |
| -- | -- |
| `ci/lint` | Nixfmt, Statix, Deadnix and source Markdown formatting |
| `ci/test/modules MODULES=dev-tools` | All evaluation and native checks for the selected module |
| `ci/test/modules MODE=eval MODULES=dev-tools` | Public structure, entry points, recommendation, `eval` and `fails` |
| `ci/test/modules MODE=run MODULES=dev-tools` | Declared native checks and local-build dry-run |
| `ci/test/modules MODE=vm MODULES=dev-tools` | Declared activation checks on native Linux with KVM |
| `ci/test/common` | Shared and platform evaluation and native checks together |
| `ci/test/common SUITE=shared MODE=eval` | Shared infrastructure assertions and diagnostics |
| `ci/test/common SUITE=platform MODE=run` | Native builder-permission regression |

The same runner can be used directly on native Linux:

```console
bash scripts/run_checks.sh module check dev-tools
bash scripts/run_checks.sh common check
bash scripts/run_checks.sh module eval dev-tools
```

For a declared VM check, use a native Linux host with an accessible `/dev/kvm`
and pass the device into the Task container:

```console
task --yes ci/test/modules MODE=vm MODULES=dev-tools CONTAINER_RUN_ARGS=--device=/dev/kvm
```

This example applies only if the module exports `vm.activation`. Native checks
in a container do not establish activation. Missing required features,
interrupted runs and skipped checks must be reported separately; they do not
become passes.

Each stage has a duration target per module; see
[Cost and reports](catalog-contract.md#cost-and-reports) for the targets and
what a report records.

Follow [Catalog checks](troubleshooting.md#catalog-checks) when a stage fails.
Manual use in a VM complements the automated checks.

## Support multiple versions

Version lines are optional. Add them when users need a supported choice; each
line is a numeric public selector suffix, not necessarily an exact upstream
patch version. A generic versioned entry declares:

```toml
description = "Example tool with two supported lines."
versions = ["1", "2"]
default = "2"
```

| Entry | Required behavior |
| -- | -- |
| `default.nix` | Only recommends line 2 with `lib.mkDefault` |
| `versions/1.nix` | Explicitly selects line 1 |
| `versions/2.nix` | Explicitly selects line 2 |
| Both explicit lines | Documented coexistence or a meaningful assertion |

Private selection options belong to `lmx.internal.<name>`. Generate packages
after the selected values have merged. Keep a default recommendation separate
from explicit selections. Several explicit lines either coexist as documented or
trigger the module's own assertion; command names remain module policy. Do not
force `config` while discovering the structure of module definitions; use normal
NixOS assertions and `mkIf`.

The harness already checks the default recommendation in both import orders. The
module owns line behavior, command aliases, capability ranking and conflicts:

| Public key | Meaning |
| -- | -- |
| `eval.line-1`, `eval.line-2` | Each line's own configuration |
| `eval.allLines` | Supported coexistence and own package/provider priority |
| `fails.twoLines` | Unsupported combination with its specific diagnostic |
| `run.commands-1`, `run.commands-2` | Actual commands for each line |
| `run.allLines` | Ordinary command resolution for supported coexistence |

Use [the lazy line helper](../catalog/_shared/test/lines.nix) to create these
per-line fixtures. It does not choose coexistence policy or expose private
package loaders. Keep additional scenarios in your own `test/`.

Keep a default fixture, one per needed line and one per different scenario.
Reuse each configuration for related assertions. Coverage follows the promises
and regression risks; there is no hard fixture-count limit.

Base packages come from the locked `pkgs`. For an additional Nixpkgs revision,
declare `lmx.pins.<revision> = <hash>` in the module and consume
`pinned.<revision>` in configuration values. Do not fetch/import another Nixpkgs
package set in a module-private package helper. Keep release maps and package
helpers module-local; neither naming convention is public ABI.

| Support status | README and warning |
| -- | -- |
| End of life | Cite the upstream policy and emit the module's warning |
| Supported | Record the policy used; no EOL warning |
| Unconfirmed | Say unknown; do not invent support dates |

Check support status during maintenance. Selecting a line does not update that
status automatically. A catalog release announces default changes and line
removals; removal needs a migration and link to the previous release.

## Catalog maintenance

### Update the NixOS base

The root `flake.nix` selects the NixOS release; `flake.lock` fixes its revision.
To update the revision within that release:

```console
task --yes nixpkgs/update
```

To change the release, update `inputs.nixpkgs.url` first. Review the lock
change, update [Concepts](concepts.md#nixos-version-and-package-pins), and
validate module/shared eval and run stages. Perform the required activation
tests before release. Module-local additional pins remain separate from this
base update.

### Prepare the documentation

```console
task --yes docs/prepare
```

This prepares `build/docs/` from guide and module sources; it does not render
HTML. Edit sources, not that generated directory. `MODULES_REF=v4` selects a
release tag for source links. The
[docs repository](https://github.com/limanix/docs) builds the site from this
output.

## Next steps

- [Concepts](concepts.md): configuration and package pins.
- [Catalog contract](catalog-contract.md): complete public interface.
- [Troubleshooting](troubleshooting.md): inspect failed evaluation or execution.
