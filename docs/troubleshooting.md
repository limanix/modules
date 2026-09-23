# Troubleshooting

Start with the step that failed: **selection**, **import**, or **VM update**.
Importing files and applying a NixOS configuration are separate operations.

## A module cannot be selected

Check the catalog available to your installed client:

```console
limanix modules list
limanix modules list --json
```

| Symptom                             | What to check                                                       | Action                                                                                                              |
|-------------------------------------|---------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| Unknown `lmx:` module               | The exact identifier must appear in the local catalog.              | Copy its spelling from `modules list`. A module present in the repository may be absent from your installed client. |
| A version is missing                | Only versions listed in the bundled catalog can be selected.        | Choose a listed version. Adding a suffix does not download another version.                                         |
| `git` or `./tools.nix` is rejected  | The TOML list accepts identifiers, not bare names, paths, or globs. | Use `lmx:git`, or import your directory and select `third-party:tools`.                                             |
| An unknown namespace is rejected    | The supported namespaces are `lmx:` and `third-party:`.             | Use an identifier from `modules list`.                                                                              |
| `third-party:tools` cannot be found | The module must be imported into the current local registry.        | Run `limanix modules add tools ./modules/tools`, then check the list again.                                         |

Use the unqualified name in import commands and the full identifier in TOML:

```console
limanix modules add dev-tools ./modules/dev-tools
```

```toml
[nixos]
modules = ["third-party:dev-tools"]
```

See [Using modules](using-modules.md) for the complete selection workflow.

## Importing a directory fails

| Symptom                     | What to check                                                                                                              | Action                                                                                       |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| Invalid module name         | Names start with a lowercase letter and use lowercase letters, digits, and separating hyphens. The limit is 63 characters. | Use a name such as `dev-tools`. Do not include `third-party:` in the command argument.       |
| Entry point is missing      | The selected directory must contain `default.nix` at its root.                                                             | Point the command at the module directory, not an individual file or its parent.             |
| Entry point is invalid      | `default.nix` must be a regular file.                                                                                      | Replace a directory or symbolic link with an ordinary file.                                  |
| Unsupported file or symlink | The copied tree may contain only regular files and directories.                                                            | Replace links with the files they reference. Remove sockets, FIFOs, and other special files. |
| Module already exists       | Import does not replace an existing name.                                                                                  | Follow the replacement steps below, or import under a different name.                        |

The directory argument is relative to **your shell's current directory**.
Paths inside Nix imports are relative to the Nix file that contains them.
Keep imported files inside the module tree:

```text
dev-tools/
├── default.nix
└── packages.nix
```

```nix
{
  imports = [ ./packages.nix ];
}
```

A path such as `../shared/packages.nix` does not copy that external file into the module. 
See [Writing a module](writing-modules.md) for a complete example.

## My edits do not appear in the VM

There are three separate copies: **your source directory → local registry → VM configuration**. 
Editing the first does not update the other two.

After editing an already imported `dev-tools` module, replace its registry copy:

```console
limanix modules remove dev-tools
limanix modules add dev-tools ./modules/dev-tools
```

Only continue after the import succeeds. 
Apply the configuration to each VM that should receive the change:

```console
limanix update --config limanix.toml
```

The TOML file must still select `third-party:dev-tools`. 
Its `name` identifies the VM to update.

Removing a registry entry does not remove it from an existing VM. 
To remove the module's configuration, delete its identifier from the TOML list and run `limanix update` with that file. 
An update that still selects a removed registry entry fails until you import it again.

## Nix evaluation or the build fails

A successful import confirms the file tree was copied. 
It does **not** confirm that the Nix code evaluates or that the complete system builds.

| Error or symptom                                        | What to inspect                                           | Next step                                                                                                                             |
|---------------------------------------------------------|-----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Nix syntax error                                        | The file and line shown in the error.                     | Check braces, semicolons, quotes, and attribute names. Fix the source, reimport it, then update.                                      |
| An imported path does not exist                         | Relative imports and referenced files.                    | Keep the required files inside the imported tree and check their spelling.                                                            |
| An option does not exist                                | The option name and the NixOS version used by the client. | Check the matching NixOS option documentation. A package name is not automatically a NixOS service option.                            |
| Conflicting option definitions                          | Every definition named in the error.                      | Remove an unintended duplicate or make the definitions agree. Reordering the TOML list is not a general conflict fix.                 |
| Package file collision after selecting several versions | Packages that provide the same command or file.           | Start with one version of that tool. Selectors being accepted does not guarantee the resulting packages can share one system profile. |
| Download or package build failure                       | The failing URL or derivation in the build output.        | Resolve that failure before retrying. Reimporting unchanged files does not repair an unavailable download or a failing package build. |

For option conflicts, check whether your module redefines a value supplied by Limanix, such as the hostname, guest user, filesystems, or Lima services. 
Prefer the TOML setting when Limanix exposes one. 
Avoid overriding the VM's platform configuration to make an unrelated module work.

`lib.mkForce` changes definition priority; it is not a universal repair. 
Read [NixOS option priorities](https://nixos.org/manual/nixos/stable/#sec-option-definitions-setting-priorities) before deliberately overriding another definition.

## An update failed or interrupted my session

**An update stops and restarts the VM.** Save active work before applying it.

Inspect the current state after a failure:

```console
limanix list
```

Keep the update output: it identifies whether the failure happened during input validation, VM preparation, the NixOS rebuild, or restart.

```{important}
A failed update is not an automatic rollback of the whole operation. 
The VM may already have stopped, and configuration or environment files may already have changed. 
Do not assume that everything still matches the previous update.
```

Correct the reported problem, replace a changed module's registry copy, and retry `limanix update --config limanix.toml`. 
Use the same VM name in that file.
If the VM is running, inspect it through `limanix shell NAME`; replace `NAME` with the name shown by `limanix list`.
