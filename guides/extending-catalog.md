---
myst:
  heading_anchors: 2
---

# Catalog development

This page describes how to add and update catalog entries in this repository.
Each entry is a directory under `catalog/`, and its name becomes the selector: `catalog/jq-tools/` provides `lmx:jq-tools` in the clients that bundle it.
For a module that only your project uses, [write a custom module](writing-modules.md) instead.

## Add an entry

An entry needs four files:

| File | Purpose |
| --- | --- |
| `default.nix` | The NixOS module that the selector loads |
| `module.toml` | The description shown by `limanix modules list`, and optional version lines |
| `check.nix` | A test of what the module adds to the NixOS configuration |
| `README.md` | The entry's page in the documentation |

For example, an entry that installs `jq` uses this `catalog/jq-tools/default.nix`:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
}
```

Its `catalog/jq-tools/module.toml`:

```toml
description = "jq for inspecting and transforming JSON."
```

And its `catalog/jq-tools/check.nix`:

```nix
{ pkgs, hasPackage, ... }:
hasPackage pkgs.jq
```

This entry takes `jq` from the [base Nixpkgs revision](concepts.md#nixos-version-and-package-pins) and has no version lines.
Add a row for the entry to the table in [Catalog](catalog.md), and write its README as described in [Write the entry's page](#write-the-entrys-page).

## Write the result check

The [test runner](../checks/default.nix) finds every entry's `check.nix`; no central list needs updating.
It evaluates the entry in a NixOS configuration and calls `check.nix` with these arguments:

| Argument | Value |
| --- | --- |
| `config` | The evaluated NixOS configuration |
| `pkgs` | The configuration's package set |
| `version` | The selected version line, or `null` for an entry without version lines |
| `userName` | The name of the test VM's user |
| `hasPackage` | A function that checks whether `config.environment.systemPackages` contains a package with the same store path |

The check must return `true`.
Accept unused arguments with `...`.
For a service, check its configuration options, because package membership does not describe what the service does.
For separately pinned packages, load the package for `version` the way [Go's check](../catalog/go/check.nix) does.

## Follow the metadata rules

The [validator](../checks/catalog.nix) enforces these rules:

| Item | Rule |
| --- | --- |
| Directory name | Up to 63 characters: lowercase letters, digits, and single hyphens between them, starting with a letter |
| `default.nix`, `module.toml`, `check.nix` | Required regular files |
| `module.toml` keys | Only `description`, `versions`, and `default` |
| `description` | A string that is not empty or only whitespace |
| `versions` | An optional list of unique version lines: up to 63 characters of digits separated by dots |
| `default` | One of `versions`; empty or omitted when there are no versions |
| `versions/<line>.nix` | A regular file for every version line |

Every directory directly under `catalog/` must be an entry.
For example, `jq-tools` and `3.14` are valid; `my_module` and `v3.14` are not.

```{warning}
Keep selectors unique across the catalog.
An entry `tools` with version line `2` and an entry named `tools-2` both provide `lmx:tools-2`.
The validator and the client reject this collision.
```

## Add version lines

Use the [Go entry](../catalog/go/README.md) as a working example.
Its `module.toml` declares the lines and the default:

```toml
versions = ["1.24", "1.25", "1.26", "1.27"]
default = "1.27"
```

Its `default.nix` loads the default line:

```{code-block} nix
:linenos:
:name: catalog-default-version
:class: code-example

let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
import (./versions + "/${metadata.default}.nix")
```

| Code | Purpose |
| --- | --- |
| [2](#catalog-default-version.2){.external .code-lines} | Reads `module.toml` and parses its fields into `metadata` |
| [4](#catalog-default-version.4){.external .code-lines} | Loads the version file named by `default`, such as `versions/1.27.nix` |

Each line's file, such as `versions/1.27.nix`, passes its version to the shared module:

```nix
import ../module.nix "1.27"
```

The versioned entries share these conventions, which the validator does not require:

| File | Contents |
| --- | --- |
| `releases.nix` | For each line: the pinned Nixpkgs revision and hash, the package attribute, the expected version, and optionally an `endOfLife` flag |
| `packages.nix` | Loads the line's packages and asserts their expected versions |
| `module.nix` | Configures packages or services for the selected line |

Modules that support several versions side by side add package priorities and versioned commands.
Modules add an evaluation warning for lines marked `endOfLife`.

When you update a tool, change its [release map](../catalog/go/releases.nix) and [package loader](../catalog/go/packages.nix) together, and keep `module.toml` and the README consistent with them.

## Write the entry's page

The entry's `README.md` becomes its page on the documentation site and on GitHub.
Follow the structure of the existing pages:

| Part | Content |
| --- | --- |
| Title and summary | The tool's name, and one or two sentences on what the module installs or configures |
| Selector | A `[nixos]` example with the default selector, and a link to applying the change |
| `Versions` | A table of selectors with the exact package versions they install, marking the default and end-of-life lines; entries without version lines describe where the package comes from |
| `Use` | The first commands to run inside the VM, and what they show |
| Additional sections | Topics specific to the entry, such as permissions, several versions, native dependencies, or editor support |

Describe what the module changes in the VM.
Link to the [client guide](https://limanix.dev/categories/client/modules.html) for Limanix commands instead of repeating them.

## Check the result

With Task and Docker installed, run from the repository root:

```console
task --yes ci/fmt ci/lint ci/test
```

| Task | Checks |
| --- | --- |
| `ci/fmt` | Nix formatting with nixfmt |
| `ci/lint` | Nix code with statix and deadnix |
| `ci/test` | The catalog metadata, NixOS evaluation, and every entry's `check.nix` |

`ci/test` evaluates both `aarch64-linux` and `x86_64-linux`; add `ARCH=arm64` or `ARCH=amd64` to evaluate one of them.
For each architecture, it evaluates:

- every entry at its default, alone and all together;
- every version line, alone and together with the other entries' defaults;
- two Docker lines together, which must fail.

```{important}
These checks evaluate configurations.
They do not build packages, boot a VM, or run the installed tools, and they do not cover every combination of several lines of one entry.
```

## Try an entry in a VM

Before a client bundles the entry, import it as a custom module on your Mac:

```console
limanix modules add jq-tools ./catalog/jq-tools
```

Select `third-party:jq-tools` in a test VM, apply the change, and run the commands from the entry's README.
An import always loads `default.nix`.
For versioned entries, this tests the default line.

<details>
<summary>Test another version line</summary>

1. In `catalog/go/module.toml`, temporarily set `default = "1.26"`.
2. Import the entry under a test name: `limanix modules add go-test ./catalog/go`.
   If that name is already registered, remove it first with `limanix modules remove go-test`.
3. Make `third-party:go-test` the only Go selector in the test VM's configuration, and apply the change.
4. Check `go version` and the README's commands inside the VM.
5. Restore the original `default`.

Restoring the file does not change the imported copy or the VM.
Remove and import the entry again for each line that you test.

</details>

## Update the NixOS base

Two kinds of pins control package versions:

| Pin | Controls |
| --- | --- |
| The root `flake.nix` and `flake.lock` | The NixOS release and exact Nixpkgs revision of the base system, used by the catalog checks and by the clients that bundle the catalog |
| An entry's `releases.nix` | The separately pinned packages of that entry |

To move the base to the newest revision of the selected NixOS release, run:

```console
task --yes nixpkgs/update
```

The task runs Nix in Docker and does not need a local Nix installation.
To change the NixOS release, edit `inputs.nixpkgs.url` in `flake.nix` and run the same task.
Then review the `flake.lock` change, update the release named in [NixOS version and package pins](concepts.md#nixos-version-and-package-pins), and run `ci/test`.
Before releasing, create and update a VM with a client built from the changed catalog.

The client owns the VM's bootstrap image and `system.stateVersion`; changing this pin changes neither.

## Prepare the documentation

The documentation site reads a prepared copy of `guides/` and every entry's README.
To create it, run:

```console
task --yes docs/prepare
```

The task replaces `build/docs/`, which Git ignores, with the pages, examples, and navigation for the site.
Links to Nix files in this repository point at the current commit; add `MODULES_REF=v4` to point them at a release tag instead.
Edit the sources, never `build/docs/`.

The task does not render HTML or check the complete site.
The [docs repository](https://github.com/limanix/docs) builds and previews the whole site from this output.
