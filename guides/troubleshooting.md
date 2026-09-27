---
myst:
  heading_anchors: 2
---

# Troubleshooting

This page covers errors in module code and programs that fail inside the VM.
For failed imports, VMs that do not start, and interrupted updates, see the client's [Troubleshooting](https://limanix.dev/categories/client/troubleshooting.html).

## Read a Nix error

When a module contains an error, `limanix create` or `limanix update` fails and prints the output of the NixOS build.
Find the last `error:` line in that output; it states the cause.
The lines above it show what Nix was evaluating, often with a file name and line number.

File paths such as `/nix/store/…-source/modules/0002/default.nix` point to the copies that the client made.
The number is the module's position in `nixos.modules`, counting from `0000`.

## Errors in module code

| The error contains | Cause | Fix |
| --- | --- | --- |
| `syntax error, unexpected` | A missing `;`, bracket, or quote | Check the reported line and the line before it |
| `undefined variable 'pkgs'` | The module uses `pkgs` without requesting it | Start the module with `{ pkgs, ... }:` |
| `attribute '…' missing` | A package name that does not exist in Nixpkgs | Look up the attribute name in the [package search](https://search.nixos.org/packages) |
| `The option … does not exist` | A misspelled option, or an option that the catalog's NixOS release does not have | Look up the option in the [option search](https://search.nixos.org/options) for the [pinned release](concepts.md#nixos-version-and-package-pins) |
| `has conflicting definition values` | Two modules set different values for the same option | See [Combine with other modules](writing-modules.md#combine-with-other-modules) |
| `is defined multiple times while it's expected to be unique` | Two modules set an option that allows one definition, such as two Docker versions | Remove one of the definitions |
| `path '…' does not exist` | An import points to a missing file or outside the module directory | Keep imported files inside the module directory |
| `infinite recursion encountered` | An `if` that reads `config` decides what the module defines | Wrap the conditional settings in [`lib.mkIf`](https://nixos.org/manual/nixos/stable/#sec-option-definitions-delaying-conditionals) |

If the conflicting option belongs to the base system, such as the hostname or the guest account, remove it from the module and change it in `limanix.toml`; see [The base system](concepts.md#the-base-system).

For a failed download, check the reported URL and the VM's network access before retrying.
For a compilation or test failure, read the failing package's build log for the cause.
Use [`nix log`](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-log.html) inside the VM with the `.drv` path from the error to see the available log.

## Warnings

Warnings do not stop the build.
When you select an end-of-life version line, the output contains a warning such as:

```text
evaluation warning: Docker Engine 28.5.2 no longer receives upstream security updates.
```

To stop the warning, select a supported line from the module's page.

## A program fails inside the VM

Run the failing command inside the VM and read its complete error.

| Symptom | Cause and next step |
| --- | --- |
| `command not found` | The module is not selected or not applied yet, or the package's command has another name, such as `rg` for `pkgs.ripgrep` |
| A change to a custom module has no effect | The VM still uses the previously imported copy; [replace the imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) and update the VM |
| An unexpected version of a command runs | Two packages provide the same command; see [Combine with other modules](writing-modules.md#combine-with-other-modules) |
| `Could not start dynamically linked executable` | The program was built for another Linux distribution; see [Downloaded programs](native-dependencies.md#downloaded-programs) |
| `cannot open shared object file`, for example for `libstdc++.so.6` | A native extension or program needs a library; see [Native dependencies](native-dependencies.md) |
| `Exec format error` | The program was built for another architecture than the VM's `resources.arch`; use a build for that architecture |

To see which package provides a command, run `readlink -f "$(command -v go)"` with the command's name instead of `go`.
