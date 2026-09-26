---
myst:
  heading_anchors: 2
---

# Contributing to the catalog

A catalog entry becomes available as an `lmx:` selector in clients that bundle it.
For a module used only by you or your team, follow [Write your first module](writing-modules.md) instead.

## Add a module

Create a directory with an entry point, metadata, a result check, and a README:

```text
catalog/jq-tools/
├── check.nix
├── default.nix
├── module.toml
└── README.md
```

This is an example of a new entry, not a module already in the catalog.
Create `catalog/jq-tools/default.nix`:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
}
```

Create `catalog/jq-tools/module.toml`:

```toml
description = "jq for inspecting and transforming JSON."
```

Write the README following the existing module READMEs: explain how to enable the module, its versions, and a useful example.
Include any permissions or limitations that affect its use.
The directory name determines the selector: `jq-tools` becomes `lmx:jq-tools`.
This example uses the consuming VM's Nixpkgs and declares no separate versions.

Create `catalog/jq-tools/check.nix` to check what the module adds to the NixOS configuration:

```nix
{ pkgs, hasPackage, ... }:
hasPackage pkgs.jq
```

`hasPackage` checks that the system package list contains the expected package by comparing its exact Nix store path.
The check must return `true`; `false` fails `ci/test`.
The test runner discovers each module's `check.nix` automatically.
Adding a module does not require editing `checks/default.nix`.

| Check argument | Value |
| --- | --- |
| `config` | Evaluated NixOS configuration |
| `pkgs` | Package set used by that configuration |
| `version` | Selected version string, or `null` for a module without versions |
| `userName` | Test VM user's name |
| `hasPackage` | Function that checks membership in `config.environment.systemPackages` |

Use `...` to accept arguments the check does not need.
For a service module, check the relevant configuration options instead of a package.

Before opening a contribution:

1. Add the entry to the overview in [Module catalog](catalog.md).
2. Run the local checks below.
3. Try the module in a test VM using the commands from its README.

To try a new entry before a client bundles it, import its directory as a custom module:

```console
limanix modules add jq-tools ./catalog/jq-tools
```

Then use `third-party:jq-tools` in your VM configuration.
Follow [Use catalog modules](using-modules.md) to create or update the VM.
Custom imports load `default.nix`; `third-party:` does not expose the version selectors from `module.toml`.
For versioned entries, see {ref}`Test a non-default version <catalog-test-version>`.

## Metadata rules

The [catalog validator](../checks/catalog.nix) checks these rules:

| Item | Rule |
| --- | --- |
| Module directory | At most 63 characters; lowercase letter first; lowercase letters, digits, and single separating hyphens |
| `default.nix` | Required regular file |
| `module.toml` | Required regular file |
| `check.nix` | Required regular file; checks the module's result |
| `description` | Non-empty string, not just whitespace |
| `versions` | Optional list of unique selector strings |
| Version selector | At most 63 characters; digits separated by dots, such as `24` or `3.14` |
| `default` | A declared selector when versions exist; otherwise empty or omitted |
| Version entry point | Regular `versions/<selector>.nix` file for every declared selector |
| Other metadata keys | Rejected |

Use names such as `jq-tools` or `nodejs`.
Names such as `MyModule`, `my_module`, and `my--module` are invalid.
A selector such as `3.14` is valid; `v3.14` and `latest` are not.

```{warning}
Keep catalog selectors unique across modules.
A module named `tools` with version selector `2` and a separate module named `tools-2` both expose `lmx:tools-2`.
Both `ci/test` and the client reject this catalog as a duplicate selector.
An imported module named `tools-2` is valid: `third-party:tools-2` refers to that literal registry name.
```

Every direct entry under `catalog/` must be a module directory.
Keep shared documentation in `guides/` and each module's documentation in its own README.

## Add version selectors

Use the existing [Go module](../catalog/go/README.md) as an example of the versioned layout:

```text
catalog/go/
├── README.md
├── check.nix
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

| File | Purpose |
| --- | --- |
| `module.toml` | Available selectors and the default |
| `default.nix` | Loads the default selector |
| `check.nix` | Checks the evaluated module's result for the selected version |
| `versions/<selector>.nix` | Passes the selector to the shared module |
| `module.nix` | Adds packages or services to NixOS |
| `packages.nix` | Loads packages and checks their versions |
| `releases.nix` | Records package choices, source revisions, and hashes |

The last three filenames are conventions used by the existing versioned modules.
The validator's required files are listed in the metadata table above.

For example, Go's metadata contains:

```toml
description = "Go compiler, gopls language server, Delve debugger, and GCC."
versions = ["1.24", "1.25", "1.26", "1.27"]
default = "1.27"
```

Its default entry point reads the metadata:

```nix
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
import (./versions + "/${metadata.default}.nix")
```

A version entry point supplies one selector:

```nix
import ../module.nix "1.27"
```

## Update a version

The versioned modules pin Nixpkgs by revision and content hash.
Their package loaders assert the expected package versions.
Review [Go's release map](../catalog/go/releases.nix) and [package loader](../catalog/go/packages.nix) together.

1. Record the package source revision, correct hash, and expected versions in the release map.
2. Add or update the selector's entry point and package selection.
3. Update `module.toml` if the supported selectors change.
4. Change the default only when the contribution is intended to change it.
5. Update the module's README with the exact versions and any command or behavior changes.
6. Run the checks and try the documented workflow in a VM.

For modules that provide several versions together, check the versioned commands and which tools the ordinary command names select.
Docker supports one selected version per VM.

(catalog-test-version)=
### Test a non-default version

The versioned layout above loads the `default` from the registered copy of `module.toml`.
To try Go `1.26` in an existing `module-lab` test VM, run these steps on your **Mac** from the repository root.
Replace `limanix.toml` below with the path to that VM's existing configuration.

1. Note the current `default` in `catalog/go/module.toml`, then temporarily set it to `"1.26"`.
2. If `go-test` is already registered, run `limanix modules remove go-test` first.
   Register the changed source:

   ```console
   limanix modules add go-test ./catalog/go
   ```

3. Use `third-party:go-test` as the only Go selector in your test VM's `nixos.modules` list in `limanix.toml`.
   Apply the change and check the selected version:

   ```console
   limanix update --config limanix.toml
   limanix shell module-lab -- go version
   ```

4. Run the module's documented workflow inside the VM, then restore the original `default` in your source `module.toml`.

Restoring the source file does not change the registered copy or the VM.
To test another selector, repeat the steps, including removing and re-adding `go-test` before updating the VM.
See [Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) for the registry replacement rules.

## Update the NixOS base

The root `flake.nix` selects the NixOS release; `flake.lock` fixes its exact Nixpkgs revision and content hash.
The catalog checks and clients that bundle this catalog use the same locked input.
The package pins in each module's `releases.nix` are separate.

To update Nixpkgs within the selected release, run from the repository root with Task and Docker installed:

```console
task --yes nixpkgs/update
```

The task runs Nix in Docker and updates the root `flake.lock`.
You do not need Nix installed on your Mac.

Each PR also runs the update in its disposable CI checkout and publishes a **Nixpkgs updates** job summary.
It shows the pinned and available commits, links to their differences, and reports when the lookup could not be completed.
The check does not commit changes, push to the PR branch, or block merging.

To change the NixOS release, edit `inputs.nixpkgs.url` in `flake.nix`, then run the same command.
Review the lock diff and run `task --yes ci/test`, which evaluates both supported architectures.
Try creating and updating a VM with a client built from the changed catalog before releasing it.
Users receive the new base through a client release that bundles the new catalog tag.

The client owns the bootstrap image and `system.stateVersion`.
Changing the catalog's Nixpkgs pin does not change either setting.

(catalog-releases)=
## How catalog changes reach users

1. A maintainer pushes a catalog tag such as `v1` or `v2` for a commit on `main`.
2. The modules release workflow checks the tag and creates a GitHub release.
3. It sends the tag to the client repository in a `limanix-modules-release` event.
4. The client workflow builds and publishes client releases that bundle this catalog.

A module release does not change installed clients or existing VMs.
Users install a client containing the new catalog, then update their VMs to apply its modules.

## Run local checks

With Task and Docker available, run from the repository root:

```console
task --yes ci/fmt
task --yes ci/lint
task --yes ci/test
```

| Command | Checks |
| --- | --- |
| `ci/fmt` | Nix formatting with `nixfmt` |
| `ci/lint` | Nix code with `statix` and `deadnix` |
| `ci/test` | Catalog metadata, NixOS evaluation, and expected module results |

`ci/test` covers both `aarch64-linux` and `x86_64-linux`.
To evaluate just one architecture:

```console
task --yes ci/test ARCH=amd64
task --yes ci/test ARCH=arm64
```

For each architecture, the checks evaluate each default, all defaults together, each declared version, and each version together with the other modules' defaults.
They also check that selecting two different declared Docker versions fails.

```{important}
These checks evaluate NixOS configurations.
They do not build packages, boot a VM, or run the installed tools.
They also do not cover every combination of several versions of one module.
```
