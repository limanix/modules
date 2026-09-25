# Contributing to the catalog

A catalog contribution makes a module available under an `lmx:` selector in clients that bundle the updated catalog.
For a personal or team module, start with [Writing a module](writing-modules.md) and [Reusable modules](reusable-modules.md).
You do not need to change this repository to use your own NixOS configuration.

This page covers the catalog's file layout and local checks. 
The release process is documented on the documentation site.

## Add a small module first

The smallest catalog entry has two files. 
For example, a new `jq-tools` entry would look like this:

```text
modules/
└── jq-tools/
    ├── default.nix
    └── module.toml
```

Create `modules/jq-tools/default.nix`:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
}
```

Create `modules/jq-tools/module.toml`:

```toml
description = "jq for inspecting and transforming JSON."
```

Here, `pkgs.jq` uses the consuming VM's Nixpkgs. 
This example does not introduce a separate package pin or a version selector.

**The directory name becomes the catalog name.** 
Once bundled into a client, the entry is selected as `lmx:jq-tools`:

```toml
[nixos]
modules = ["lmx:jq-tools"]
```

```{note}
Editing a catalog checkout does not change the catalog embedded in an installed client. 
To try the module before it is bundled, import its directory as a third-party module using the workflow in [Reusable modules](reusable-modules.md).
```

## Follow the metadata contract

The catalog validator checks the following rules:

| Item                  | Rule                                                                                                           |
|-----------------------|----------------------------------------------------------------------------------------------------------------|
| Directory name        | At most 63 characters; begins with a lowercase letter; lowercase letters, digits and single separating hyphens |
| `default.nix`         | Required regular file: the module's default entry point                                                        |
| `module.toml`         | Required regular file                                                                                          |
| `description`         | Required non-empty string; whitespace alone is invalid                                                         |
| `versions`            | Optional list of unique strings; omitted means no version selectors                                            |
| Version selector      | At most 63 characters; digits separated by dots, such as `24` or `3.14`                                        |
| `default`             | Must name a declared selector when `versions` is non-empty; otherwise omitted or empty                         |
| Version entry point   | Every selector requires a regular `versions/<selector>.nix` file                                               |
| Extra metadata fields | Rejected; the allowed keys are `description`, `versions` and `default`                                         |

Valid names include `jq-tools`, `python` and `nodejs`. Names such as `MyModule`, `my_module`, `1tool` and `my--tool` are invalid.
Selectors such as `3.14` are valid; `v3.14`, `latest` and `3.14-beta` are invalid.

Every immediate entry under `modules/` must be a module directory. 
Keep shared catalog documentation outside that directory.

Source: [catalog validator](https://github.com/limanix/modules/blob/main/checks/catalog.nix).

## Add version selectors when needed

The existing versioned modules share this layout:

```text
modules/go/
├── default.nix
├── module.toml
├── module.nix
├── packages.nix
├── releases.nix
└── versions/
    ├── 1.24.nix
    ├── 1.25.nix
    ├── 1.26.nix
    └── 1.27.nix
```

| File                      | Responsibility                                           |
|---------------------------|----------------------------------------------------------|
| `module.toml`             | Lists supported selectors and the default                |
| `default.nix`             | Imports the selector named by metadata                   |
| `versions/<selector>.nix` | Passes a selector into the shared module                 |
| `module.nix`              | Configures NixOS and installs the selected tools         |
| `packages.nix`            | Loads the selected package source and checks its version |
| `releases.nix`            | Records source revisions, hashes and package choices     |

The last three filenames are a repository convention, not additional metadata requirements. 
The validator requires the entry points and metadata described above.

For example, Go declares:

```toml
description = "Go compiler, gopls language server, and Delve debugger."

versions = ["1.24", "1.25", "1.26", "1.27"]
default = "1.27"
```

Its `default.nix` reads that choice:

```nix
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
import (./versions + "/${metadata.default}.nix")
```

Its `versions/1.27.nix` supplies the selector:

```nix
import ../module.nix "1.27"
```

The shared `module.nix` accepts that string first, then the normal NixOS module arguments. 
This keeps the NixOS configuration in one place.

## Pin a package source

Versioned entries fetch Nixpkgs by a specific Git revision and content hash.
`packages.nix` selects a package from that source and asserts its expected version. 
Read the existing [Go package loader](https://github.com/limanix/modules/blob/main/modules/go/packages.nix) and [release map](https://github.com/limanix/modules/blob/main/modules/go/releases.nix) as a complete example.

When adding a selector to that pattern:

1. Record the Nixpkgs revision and its correct source hash in `releases.nix`.
2. Add the selector's package attribute and exact expected package version.
3. Add `versions/<selector>.nix` pointing to the shared module.
4. Add the selector to `module.toml`; change `default` only if that is part of the update.
5. Update the module's examples and the [catalog reference](catalog.md).
6. Run the checks below, then test the behavior in a VM.

Keep version assertions and hashes consistent with the actual source. 
Changing only a displayed version string does not select a different package.

For modules that support several toolchains together, review the unqualified command priority and versioned wrappers as well. 
For a service such as Docker, document that only one selected version is supported.

## Run the repository checks

From the repository root, use the existing Taskfile entry points:

```console
task --yes ci/fmt
task --yes ci/lint
task --yes ci/test
```

| Command   | Checks                                               |
|-----------|------------------------------------------------------|
| `ci/fmt`  | Nix formatting through `nixfmt`                      |
| `ci/lint` | Nix code through `statix` and `deadnix`              |
| `ci/test` | Catalog structure and NixOS configuration evaluation |

The Taskfile imports the shared Nix tooling at the pinned `v0.0.4` revision.
It is the entry point for the repository's validation commands.

Without `ARCH`, `ci/test` evaluates both `aarch64-linux` and `x86_64-linux`.
To evaluate one architecture, pass `ARCH`:

```console
task --yes ci/test ARCH=amd64
task --yes ci/test ARCH=arm64
```

The PR workflow runs these two commands in parallel. Each architecture uses the same cases:

| Case                 | Selected modules                                             |
|----------------------|--------------------------------------------------------------|
| Each default         | One module's `default.nix`                                   |
| All defaults         | Every module's `default.nix` together                        |
| Each version         | One declared version entry point                             |
| Version with catalog | All defaults, with one module replaced by a declared version |

```{important}
These checks evaluate NixOS derivations. 
They do not build the packages, boot a VM or run the installed tools. 
They also do not try every combination of several versions of the same module.
```

For runtime validation, use the module in a test VM. 
Check the commands or service it adds. 
If it supports several versions together, select that combination and check both the ordinary and versioned commands.

Sources: [Taskfile](https://github.com/limanix/modules/blob/main/Taskfile.yml), [evaluation matrix](https://github.com/limanix/modules/blob/main/checks/default.nix) and [test VM configuration](https://github.com/limanix/modules/blob/main/checks/nixos.nix).
