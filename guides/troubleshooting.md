# Troubleshooting

Start with the step that failed.
The client guide covers registry and VM operations; this page covers Nix and programs inside the guest.

| Problem | Start here |
| --- | --- |
| A selector is missing or rejected | [List available modules](https://limanix.dev/categories/client/modules.html#list-available-modules) |
| `modules add` fails | [Import a module](https://limanix.dev/categories/client/modules.html#import-a-module) |
| An edit has no effect | [Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) |
| Nix reports an error | [Read the build failure](#nix-evaluation-or-build-fails) |
| A project build needs tools or system libraries | [Check native dependencies](native-dependencies.md) |
| A program or import fails after installation | [Check the runtime error](#a-program-fails-after-installation) |
| An update stopped or failed | [Create or update failed during provisioning](https://limanix.dev/categories/client/troubleshooting.html#create-or-update-failed-during-provisioning) |

(nix-evaluation-or-build-fails)=
## Nix evaluation or build fails

Read the original Nix error from `limanix create` or `limanix update`.

| Error | Next step |
| --- | --- |
| Syntax error | Check the reported file and line for missing braces, semicolons, or quotes |
| File does not exist | Check import paths and keep required files in the module directory |
| Option does not exist | Check its spelling and availability in NixOS 26.05, which the current catalog pins |
| Conflicting definitions | Compare the definitions named in the error and remove or resolve the conflict |
| Package file collision | Compare the package paths in the error and {ref}`resolve the overlapping files <package-file-collisions>` |
| Download or build failure | Read the failing URL or package error before retrying |

After changing a custom module, follow [Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module) before retrying.
For a conflict, check whether you are redefining VM settings such as the hostname, user, or filesystems.
Use the TOML setting when Limanix provides one.
{ref}`Option priorities <understand-how-settings-combine>` explain when to use `mkDefault` or `mkForce`.

(package-file-collisions)=
### Resolve package file collisions

Two packages can provide different files at the same installed path, such as a command in `bin/`.
Check the package paths in the error and the custom modules that add them.
Remove an unwanted package, or wrap the preferred package with [lib.hiPrio](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.meta.hiPrio) in `environment.systemPackages`.
Keep the other package at its default priority.
Catalog modules that support installing multiple versions together already set package priorities.
These package priorities are separate from the `mkDefault` and `mkForce` option priorities.

(a-program-fails-after-installation)=
## A program fails after installation

A successful VM update or package installation does not prove that a program can run.
Run the failing command **inside the VM** and read the full error.

| Symptom | What to check |
| --- | --- |
| `command not found` | Check the command name and `PATH` inside the VM; for catalog tools, also check that the module is selected and applied |
| `libstdc++.so.6: cannot open shared object file`, or another missing shared library | The program or native extension needs runtime libraries; see {ref}`Run prebuilt code <native-runtime-dependencies>` |
| `No such file or directory` although the executable exists | Check the script interpreter or binary loader; see {ref}`Run prebuilt code <native-runtime-dependencies>` for NixOS compatibility |
| `Exec format error` | Check that the executable targets Linux and the VM's architecture from `resources.arch` |

For missing build tools or headers reported by a project's install command, see {ref}`Configure build dependencies <native-build-dependencies>`.
