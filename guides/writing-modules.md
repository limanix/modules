# Write a module

Start with a `default.nix` that adds packages, then extend it with program settings, services, or native libraries as needed.
A custom module needs no catalog metadata and no flake.
If you want to contribute it to this repository, continue with [Add to the catalog](#add-to-the-catalog); that step is optional.

[Concepts](concepts.md) explains the NixOS configuration model.
This guide introduces the Nix syntax through examples.

| Your task | Start here |
|---|---|
| Write a custom module | [Create a module](#create-a-module) |
| Add or maintain a catalog module | [Catalog contract](catalog-contract.md), then [Add to the catalog](#add-to-the-catalog) |
| Understand required tests | [Required checks](catalog-contract.md#required-checks-for-every-module) |

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

The module adds `jq` and `ripgrep` to the VM.
Download: {download}`default.nix <examples/dev-tools/default.nix>`.

### Read the module

The file describes the desired configuration, not a sequence of installation commands.
Its assignment sets `environment.systemPackages`, the NixOS option that lists packages to install for all users.

| Code                                                       | Meaning                                                                                                                                |
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| [1](#custom-module-dev-tools.1){.external .code-lines}     | A function that receives `pkgs` from NixOS; `...` accepts the other arguments it does not use                                          |
| [2–7](#custom-module-dev-tools.2-7){.external .code-lines} | The function returns a set of settings, enclosed in braces                                                                             |
| [3–6](#custom-module-dev-tools.3-6){.external .code-lines} | Assigns a list of packages to the option; list entries are separated with spaces, not commas, and the assignment ends with a semicolon |

`pkgs` is the package set supplied to the module.
`pkgs.jq` selects the `jq` package from it, and `pkgs.ripgrep` selects the package that provides the `rg` command.

### Find packages and options

To adapt the module, look up the software or setting you need:

| Search                                              | Use it for                                           |
|-----------------------------------------------------|------------------------------------------------------|
| [NixOS packages](https://search.nixos.org/packages) | Package attributes, such as `jq` to use as `pkgs.jq` |
| [NixOS options](https://search.nixos.org/options)   | Option names, types, defaults, and examples          |

In both searches, select the NixOS release that the catalog pins; [NixOS version and package pins](concepts.md#nixos-version-and-package-pins) names it.
A package's attribute name can differ from its command, as with `ripgrep` and `rg` above.

## Configure programs and services

Adding a package to `environment.systemPackages` makes its commands available, but does not configure the program.
Program and service options can handle that setup as well as install the software.
This module installs Neovim and makes it the default editor:

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

| Code                                                    | Meaning                                                                     |
|---------------------------------------------------------|-----------------------------------------------------------------------------|
| [2–5](#custom-module-neovim.2-5){.external .code-lines} | Groups Neovim's settings in a nested set                                    |
| [3](#custom-module-neovim.3){.external .code-lines}     | Enables Neovim with the Boolean value `true`; Boolean values have no quotes |
| [4](#custom-module-neovim.4){.external .code-lines}     | Makes Neovim the default editor                                             |

### Arguments and nested settings

The `defaultEditor` assignment above can also be written as `programs.neovim.defaultEditor = true;`.
The dots describe nested settings: `defaultEditor` inside `neovim`, inside `programs`.
The nested form is useful when setting several options for one program.

This module needs no `{ pkgs, ... }:` header because it uses no arguments; the first example needs `pkgs` to select packages.
Modules can also request `lib`, a library of helper functions, and `config`, the final configuration after all modules are merged.

### Read VM user settings

LimaNix exposes the guest account through typed NixOS options.
Read these through `config` instead of hard-coding values such as the user name `dev`:

```nix
{ config, pkgs, ... }:
{
  users.users.${config.limanix.user.name}.packages = [ pkgs.jq ];
}
```

| Option | Type | Value |
|---|---|---|
| `limanix.user.name` | string, read-only | Guest account name supplied by the client |
| `limanix.user.home` | string, read-only | Guest home directory supplied by the client |
| `limanix.user.shell` | shell package | Login shell; Bash by default, or Zsh with `lmx:zsh` |

These three options are declared in the shared `interface.nix` at the catalog repository root.
The client supplies the account identity and applies the selected shell to the account.
Modules that use these options depend on this interface rather than the client's internal VM data layout.
Their names, types and meanings form the public contract; changing that contract requires a compatibility decision.

Select another login shell in a custom module:

```nix
{ pkgs, ... }:
{
  programs.fish.enable = true;
  limanix.user.shell = pkgs.fish;
}
```

This ordinary assignment overrides the Zsh module's `lib.mkDefault` value.
Zsh remains installed, and its shell integrations still apply to Zsh.
Two modules that offer different shells at the same priority still require an explicit choice.
Set `limanix.user.shell` rather than assigning the guest account's `users.users.<name>.shell` directly.

### Migrate custom modules

The old `runtime` and `inputs` data are no longer available as module arguments.
Custom modules that read them need changes before their next VM create or update.
Migration errors from the generated flake link to this section.
The diagnostic does not restore their values.
Catalog checks do not supply these arguments or the temporary diagnostics.
Remove these arguments from the module's function signature and replace their uses as follows:

| Previous reference | Replacement |
|---|---|
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

`pkgs.stdenv.hostPlatform` is an attribute set, not the previous `"arm64"` or `"amd64"` string.
Its `system` field is `"aarch64-linux"` or `"x86_64-linux"` for the supported guest architectures.
Values read through `config` reflect the final merged configuration, including changes from other modules.
For example, the firewall port lists can contain ports added by services as well as those configured through the client.

Standard NixOS arguments such as `config`, `lib`, `pkgs` and `modulesPath` remain available.
The generated root flake imports Lima itself; module code does not receive the root flake's `inputs` set.

### Enable a service

Services work the same way.
This module runs PostgreSQL and creates a database and a database user named after the VM's user:

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

| Code                                                          | Purpose                                                                                     |
|---------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| [1](#custom-module-postgresql.1){.external .code-lines}       | Receives the [public account settings](#read-vm-user-settings) through `config` |
| [4](#custom-module-postgresql.4){.external .code-lines}       | Enables the PostgreSQL service                                                              |
| [5](#custom-module-postgresql.5){.external .code-lines}       | Creates a database named after the VM's user                                                |
| [6–11](#custom-module-postgresql.6-11){.external .code-lines} | Creates a database user with the same name and makes it the owner of that database          |

With this configuration applied, the matching guest user can connect to the database with `psql` without a password.
Each service documents its options, including the ones it requires, in the [option search](https://search.nixos.org/options).
Keep passwords out of modules; see [Trust and secrets](concepts.md#trust-and-secrets).

## Organize and combine modules

As a module grows, separate its concerns into files and decide which settings other modules may override.

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

Each imported file is a module of its own, such as the package list and the Neovim example above.
Paths are relative to the file that contains them.
For imported third-party modules, keep every imported file inside the module directory to make it self-contained.
Standard catalog modules may import siblings, for example `imports = [ ../git/default.nix ];`.
Use the explicit entry-point file so Nix recognizes it as the same module when it is also selected directly.
The client preserves the whole catalog tree and imports only the selected entry points.
Nix then follows their imports.
This lets an aggregate such as `lmx:console` reuse the same modules that users select individually.

Catalog composition, public options, and capability exchange follow the [catalog contract](catalog-contract.md).
The contract distinguishes repeat imports from explicit version selection and defines who owns common declarations.

`imports` combines modules.
The Nix function `import ./file.nix` is different: it evaluates a file and returns its value.

### Combine with other modules

NixOS merges your module with the rest of the system configuration:

| Definitions in different modules                               | Result                                                                                   |
|----------------------------------------------------------------|------------------------------------------------------------------------------------------|
| Lists, such as `environment.systemPackages`                    | Combined                                                                                 |
| Two different values for a string option, at the same priority | The build stops with a `conflicting definition values` error                             |
| A value wrapped in `lib.mkDefault`, and an ordinary value      | The ordinary value wins                                                                  |
| A value wrapped in `lib.mkForce`                               | Replaces definitions with weaker priority, including ordinary values and `lib.mkDefault` |

Use `lib.mkDefault` for a value that other modules may replace:

```nix
{ lib, ... }:
{
  environment.variables.EXAMPLE_BUILD_MODE = lib.mkDefault "development";
}
```

Another module can then set `environment.variables.EXAMPLE_BUILD_MODE = "test";` without a conflict.
Changing the order of module imports does not resolve conflicting option values.
Use `lib.mkForce` for intentional replacement; for list options, it replaces entire lists from weaker definitions.
Definitions with the same priority still merge or conflict.

When two packages provide the same command, NixOS keeps one of them on `PATH` and the build succeeds.
To choose which one, raise the priority of the package you want:

```nix
{ lib, pkgs, ... }:
{
  environment.systemPackages = [ (lib.hiPrio pkgs.netcat-openbsd) ];
}
```

Catalog modules that support side-by-side versions already set package priorities.
Their newest selected line supplies the ordinary commands.
Inside the VM, `readlink -f "$(command -v nc)"` shows which package provides a command.

To give a module its own settings, such as an `enable` switch, see [option declarations](https://nixos.org/manual/nixos/stable/#sec-option-declarations) and [conditional definitions with `mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) in the NixOS manual.

## Handle native dependencies

You may need more than a package list when a project's dependencies compile native code or download Linux binaries.
Package managers such as pip, npm, and Cargo do not always provide the required system libraries or build tools.
NixOS keeps those dependencies under `/nix/store` instead of the conventional `/usr` and `/lib` layout.
Use the examples below for the problem you encounter; a module does not need all of them.

| What fails                    | Typical message                                                                                             | See                                                                                |
|-------------------------------|-------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| Building a dependency         | `gcc: command not found`, `fatal error: zlib.h: No such file or directory`, or `No package 'openssl' found` | [Build tools and libraries](#build-tools-and-libraries)                            |
| Starting a downloaded program | `Could not start dynamically linked executable`                                                             | [Downloaded programs](#downloaded-programs)                                        |
| Loading a native extension    | `libstdc++.so.6: cannot open shared object file`                                                            | [Native extensions in Python and Node.js](#native-extensions-in-python-and-nodejs) |

### Build tools and libraries

This example adds a compiler, make, pkg-config, and the development files of two libraries:

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

| Code                                                                   | Purpose                                                                           |
|------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| [8](#native-dependencies-build-tools.8){.external .code-lines}         | Selects each library's development output, containing its headers and `.pc` files |
| [12–13](#native-dependencies-build-tools.12-13){.external .code-lines} | Provide GCC and make for builds that require them                                 |
| [14](#native-dependencies-build-tools.14){.external .code-lines}       | Adds pkg-config, which reports a library's compiler and linker flags              |
| [18–21](#native-dependencies-build-tools.18-21){.external .code-lines} | Points pkg-config to those `.pc` files                                            |

`let … in` names values used by the returned settings, and `with pkgs;` lets the library list omit the `pkgs.` prefix.
The `++` operator joins lists.
Replace `openssl` and `zlib` with the libraries your project needs.
Keep only the build tools it uses: the catalog's Go module already includes GCC, and Rust includes GCC and pkg-config; Python and Node.js include no build tools.
`node-gyp` also needs Python, available from the [Python module](../catalog/python/README.md).

With the module applied, check inside the VM that pkg-config finds a library:

```console
pkg-config --cflags --libs openssl
```

The command prints compiler and linker flags with paths under `/nix/store`.
For a library without `.pc` files, pass its include and library directories as its build instructions describe.
The Nix toolchain records runtime paths for libraries passed to the linker; libraries loaded later can still need a search path, as described below.

### Downloaded programs

Programs built for other Linux distributions may expect a loader under `/lib` or `/lib64`.
[nix-ld](https://github.com/nix-community/nix-ld) provides it at the expected path:

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

The default library set includes the C++ runtime, zlib, OpenSSL, and curl; `libraries` adds to it.
Use this for glibc-based Linux binaries matching the VM's architecture, including those downloaded by npm, pip, or test runners.

### Native extensions in Python and Node.js

Nixpkgs interpreters use their own loader and do not automatically use nix-ld's library search path.
If a compiled extension cannot find a library, pass the nix-ld libraries to the affected command:

```console
LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" python -c "import numpy"
```

This requires nix-ld to be enabled.
Replace the command with your own, such as `python -m pytest` or `node server.js`.
In a Python virtual environment, activate the environment first.

```{warning}
Set `LD_LIBRARY_PATH` only for the command that needs it.
Setting it for the whole VM can make other programs load incompatible libraries.
```

The [nix-ld documentation](https://github.com/nix-community/nix-ld/blob/2.0.6/README.md#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld) explains this distinction.

### Other approaches

- Use a Nixpkgs package when the tool can use an installed program instead of downloading its own binary.
- Use [`python3.withPackages`](https://nixos.org/manual/nixpkgs/stable/#python.withPackages) for a Nixpkgs interpreter with its Python dependencies; this is separate from pip virtual environments.
- Run the tool in a supported Linux distribution's container with the [Docker module](../catalog/docker/README.md).

## Add to the catalog

The module is usable without becoming a catalog entry.
Continue here only if you want to contribute it to the shared catalog in this repository.
Every catalog entry follows the [catalog contract](catalog-contract.md), including its documentation and testing requirements.

Place the minimal `dev-tools` example from [Create a module](#create-a-module) in `catalog/dev-tools/`, keeping its `default.nix`.
The directory name identifies the entry and gives it the selector `lmx:dev-tools`.
Add the remaining files:

| File          | Purpose                                                                    |
|---------------|----------------------------------------------------------------------------|
| `default.nix` | The module's entry point; the existing example installs `jq` and `ripgrep` |
| `module.toml` | The catalog description and optional version lines                         |
| `check.nix`   | Checks what the module adds to the evaluated NixOS configuration           |
| `README.md`   | The entry's documentation page, including its Guarantees section             |
| `smoke.nix`    | Build and behavior checks when required by the [contract](catalog-contract.md#required-checks-for-every-module) |

For `catalog/dev-tools/module.toml`, a description is enough:

```toml
description = "jq and ripgrep for inspecting project data."
```

This entry uses the base Nixpkgs packages and needs no version lines.
Its package-only behavior needs `check.nix`; it introduces no custom build or startup behavior requiring a separate smoke check.

### Write the result check

For this two-package example, `catalog/dev-tools/check.nix` checks for both:

```nix
{ pkgs, hasPackage, ... }:
hasPackage pkgs.jq && hasPackage pkgs.ripgrep
```

The [test runner](../checks/default.nix) discovers every entry's `check.nix` and calls it with these arguments:

| Argument     | Value                                                                                          |
|--------------|------------------------------------------------------------------------------------------------|
| `config`     | The evaluated NixOS configuration                                                              |
| `pkgs`       | The configuration's package set                                                                |
| `version`    | The selected version line, or `null` for an entry without version lines                        |
| `userName`   | The test VM's user name                                                                        |
| `hasPackage` | Checks whether `config.environment.systemPackages` contains a package with the same store path |

The check must return `true`; accept unused arguments with `...`.
For a service, check its configuration options rather than only its package membership.
For separately pinned packages, load the package for `version` as [Go's check](../catalog/go/check.nix) does.

This check verifies the evaluated result only.
Custom builds and runtime integration require `smoke.nix` under the [smoke requirements](catalog-contract.md#required-checks-for-every-module).
Every such check must be discovered, built, and executed by blocking catalog CI.

### Follow the metadata rules

Catalog entries must follow these structural rules; see the [validator](../checks/catalog.nix).
The [catalog contract](catalog-contract.md) also requires README guarantees and applicable smoke checks.

| Item                                      | Rule                                                                                                      |
|-------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Directory name                            | Up to 63 characters: lowercase letters, digits, and single hyphens between groups, starting with a letter |
| Reserved names                            | `capabilities` and `internal` cannot be module names; `_shared` is reserved for shared declarations |
| `default.nix`, `module.toml`, `check.nix` | Required regular files                                                                                    |
| `module.toml` keys                        | Only `description`, `versions`, and `default`                                                             |
| `description`                             | A string that is not empty or only whitespace                                                             |
| `versions`                                | An optional list of unique version lines: up to 63 characters of digits separated by dots                 |
| `default`                                 | One of `versions`; empty or omitted when there are no versions                                            |
| `versions/<line>.nix`                     | A regular file for every version line                                                                     |

Every directory directly under `catalog/` must be an entry, except the reserved `_shared` directory.
Use `_shared/internal/` for private declarations imported by multiple catalog modules.
Public declarations belong in `_shared/<area>.nix` and are loaded by the client, including `_shared/editor.nix` for `lmx.capabilities.editor.*`.
Provider and consumer modules use these public options without importing their declaration files.
The `_shared` directory has no selector or module metadata and is excluded from generated module documentation.
The client preserves its files in the catalog source tree.
All other directory names remain subject to the module rules, and a catalog containing only `_shared` is invalid.
For example, `dev-tools` is a valid name and `3.14` is a valid version line; `my_module` and `v3.14` are not.

```{warning}
Keep selectors unique across the catalog.
An entry `tools` with version line `2` and an entry named `tools-2` both provide `lmx:tools-2`.
The validator rejects this collision.
```

### Write the entry's page

The entry's `README.md` becomes its page on the documentation site and on GitHub.
Follow the existing pages:

| Part                | Content                                                                                                                                       |
|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Title and summary   | The tool's name and what the module installs or configures                                                                                    |
| Selector            | The entry's default selector and a link to the client guide for applying it                                                                   |
| `Versions`          | Selectors and exact package versions, marking default and end-of-life lines; for an entry without lines, explain where its package comes from |
| `Use`               | The first commands to run inside the VM and what they show                                                                                    |
| `Guarantees`        | The stable behavior promised by the module, with the checks that cover it                                                                     |
| Additional sections | Entry-specific details such as permissions, native dependencies, or editor support                                                            |

Use this structure for the `Guarantees` section, with observable behavior and the checks that cover it.
The following editor and language examples illustrate the required format:

```markdown
## Guarantees

| Guarantee | Covered by |
|---|---|
| `nvim` opens AstroNvim when neither personal `init.lua` nor `init.vim` exists | `smoke.nix`: startup |
| Selecting `lmx:go` installs and declares `gopls` | `check.nix` |
| Selecting AstroNvim together with Go configures the declared `gopls` | `check.nix`, `smoke.nix`: LSP |
```

Write guarantees for the entry being documented and reference the checks that verify each guarantee.
Describe the module's behavior, without repeating client instructions.
Add its row to the table in [Catalog](catalog.md).

### Check the result

With Task and Docker installed, run from the repository root:

```console
task --yes ci/nixos-fmt ci/nixos-lint ci/test
```

Repository checks must meet the [catalog contract](catalog-contract.md#required-checks-for-every-module):

| Task | Required coverage |
|---|---|
| `ci/nixos-fmt` | Nix formatting with nixfmt |
| `ci/nixos-lint` | Nix code with statix and deadnix |
| `ci/test` | Catalog metadata, module and version evaluation, composition, public options and capabilities, and all required `check.nix` and `smoke.nix` checks |

Evaluation must cover every entry at its default, alone and with compatible defaults, every version line, composition, supported overrides, and expected incompatible selections.
Run evaluation for both `aarch64-linux` and `x86_64-linux`; `ARCH=arm64` or `ARCH=amd64` selects one architecture for a local run.
Every applicable `smoke.nix` must be discovered, built, and executed by blocking catalog CI using the module's actual packages and generated configuration.
Catalog evaluation uses the public interface with test account values; client/catalog compatibility checks must evaluate real `Prepare()` output to verify the client's values.
Reports must distinguish evaluation, build, runtime, and full-VM checks, and identify the architecture verified at each level.

Also test the applied module in a VM by running the commands documented in its README.
Keep evaluation results and runtime results distinct.
Manual VM checks complement the required automated checks; they do not satisfy the CI requirement by themselves.

## Support multiple versions

Version lines are optional, even for a catalog entry.
Use them when users need a choice of tool versions or an incompatible change requires a new supported contract line.
Document the relationship between a selector, its upstream versions, and its [compatibility guarantees](catalog-contract.md#guarantees-and-version-lines).
The [Go entry](../catalog/go/README.md) is a working example.
Its `module.toml` adds the lines and default alongside its description:

```toml
versions = ["1.24", "1.25", "1.26", "1.27"]
default = "1.27"
```

Its `default.nix` loads that default:

```{code-block} nix
:linenos:
:name: catalog-default-version
:class: code-example

let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ (./versions + "/${metadata.default}.nix") ];
}
```

| Code                                                   | Purpose                                                                |
|--------------------------------------------------------|------------------------------------------------------------------------|
| [2](#catalog-default-version.2){.external .code-lines} | Reads `module.toml` and parses its fields into `metadata`              |
| [4–6](#catalog-default-version.4-6){.external .code-lines} | Imports the concrete version file named by `default`, such as `versions/1.27.nix`, so selecting that same file again is deduplicated |

Each line's file, such as `versions/1.27.nix`, passes its version to a shared module:

```nix
import ../module.nix "1.27"
```

The versioned entries share these conventions, which the validator does not require:

| File           | Contents                                                                                                   |
|----------------|------------------------------------------------------------------------------------------------------------|
| `releases.nix` | Pinned Nixpkgs revisions and hashes, package attributes, expected versions, and an `endOfLife` value for every line |
| `packages.nix` | Loads the line's packages and asserts their expected versions                                              |
| `module.nix`   | Configures packages or services for the selected line                                                      |

Entries supporting side-by-side versions add package priorities and versioned commands.
Set `endOfLife` from the upstream project's maintenance policy:

| Value | Meaning | EOL warning |
|-------|---------|-------------|
| `true` | Upstream support for the line has ended | Yes |
| `false` | The line is supported under the upstream policy | No |
| `null` | The line's support status has not been confirmed | No |

Export the value from `packages.nix` with `inherit (release) endOfLife;`.
In `module.nix`, use `lib.optional (tools.endOfLife == true)` for the warning so an unknown status is accepted.
Mark EOL lines and unknown statuses in the README, and cite the upstream policy used to determine support.
Review the value when maintaining the catalog; the build does not update it automatically.
Keep the [release map](../catalog/go/releases.nix), [package loader](../catalog/go/packages.nix), metadata, and README consistent when updating a tool.
Test each version line's documented commands in addition to the catalog checks.

## Catalog maintenance

These repository-wide tasks are separate from writing an individual module.

### Update the NixOS base

The root `flake.nix` selects the NixOS release, and `flake.lock` fixes its Nixpkgs revision.
An entry's `releases.nix` pins its own packages separately.
To update the base revision within the selected release, run:

```console
task --yes nixpkgs/update
```

The task runs Nix in Docker; no local Nix installation is needed.
To change the NixOS release, edit `inputs.nixpkgs.url` in `flake.nix` first.
Review the resulting `flake.lock` change, update the release named in [Concepts](concepts.md#nixos-version-and-package-pins), and run `ci/test`.
Before releasing the change, verify the catalog in a VM as well.

### Prepare the documentation

The documentation site consumes a prepared copy of `guides/` and every entry's README:

```console
task --yes docs/prepare
```

The task replaces the ignored `build/docs/` directory with the pages, examples, and navigation.
Links to Nix source files point at the current commit; add `MODULES_REF=v4` to use a release tag instead.
Edit the sources, not `build/docs/`.

This task does not render HTML or check the complete site.
The [docs repository](https://github.com/limanix/docs) builds and previews the site from this output.

## Next steps

- [Nix language basics](https://nix.dev/tutorials/nix-language.html): learn more of the language used in module files.
- [Writing NixOS modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules): explore the full module system.
- [Troubleshooting](troubleshooting.md): fix errors that a module causes.
