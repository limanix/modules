# Use native dependencies

Some project dependencies contain C or C++ code, link to system libraries, or download executable files.
This affects Python, Node.js, Rust, and other toolchains.
Language package managers install project dependencies; they do not provide every system tool or library those dependencies need.

## Find the failing stage

| Failure | What to check | Next step |
| --- | --- | --- |
| A build cannot find a compiler, `make`, or Python | Build tools | {ref}`Configure build dependencies <native-build-dependencies>` |
| A build cannot find a header or pkg-config entry | Library development files or search paths | {ref}`Configure build dependencies <native-build-dependencies>` |
| An import reports a missing shared library, or an executable reports a missing loader | Runtime libraries or a compatible loader | {ref}`Run prebuilt code <native-runtime-dependencies>` |

Read the first specific error in the build or launch output.
A successful installation does not prove that a native extension can load or an executable can run.

(native-build-dependencies)=
## Configure build dependencies

Check the project's build requirements and the tools already included by your selected modules.

| Requirement | How to provide it |
| --- | --- |
| C or C++ compiler | `pkgs.gcc` |
| GNU Make | `pkgs.gnumake` |
| Library discovery with pkg-config | `pkgs.pkg-config` |
| Python for build scripts | Add a suitable `lmx:python` selector to the VM configuration |
| Library headers and `.pc` files | Select the library's development output with `lib.getDev` |

On your Mac, create `modules/native-deps/default.nix` from this template.
Keep the build tools your project needs and fill `libraries` with its required [Nixpkgs package attributes](https://search.nixos.org/packages).
Leave `libraries` empty when the build needs no additional system libraries.

```nix
{ lib, pkgs, ... }:
let
  libraries = with pkgs; [
    # Add the system libraries required by your project.
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

`lib.getDev` selects the development output when the package provides one.
The `.pc` files describe the library's header and linker settings.
`PKG_CONFIG_PATH` tells pkg-config where to find them.
For libraries without `.pc` files, follow the dependency's build instructions to set its include and library paths.

Register the module on your Mac:

```console
limanix modules add native-deps ./modules/native-deps
```

Add `third-party:native-deps` to the VM's `nixos.modules` list alongside your language modules.
Follow [Use catalog modules](using-modules.md) to apply the configuration and open a new VM shell.
After later edits, [replace the imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module), using the name `native-deps` and source directory `./modules/native-deps`.

If the build uses pkg-config, list the libraries it can find inside the VM:

```console
pkg-config --list-all
```

Then rerun the project's installation or build command from its directory.
Test the resulting program or import as well as the build.

(native-runtime-dependencies)=
## Run prebuilt code

NixOS stores libraries under `/nix/store`, rather than the conventional paths expected by many prebuilt Linux binaries.
A downloaded executable may need a different loader path, and a native extension may be unable to find its shared libraries.

```{important}
Build settings and runtime settings solve different problems.
`PKG_CONFIG_PATH` helps a build find libraries; it does not configure the runtime loader.
A Python virtual environment isolates Python packages; it does not supply their system libraries.
```

### Enable a loader for downloaded executables

For a prebuilt glibc-based Linux executable matching the VM's architecture, enable [nix-ld](https://github.com/nix-community/nix-ld) in your `native-deps` module.
For runtime support alone, save this as `modules/native-deps/default.nix`.
If that file already contains the build template above, copy only the `programs.nix-ld` setting into its existing body, beside `environment.systemPackages`:

```nix
{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add any extra runtime libraries required by your program.
    ];
  };
}
```

NixOS provides the loader and a standard set of libraries, including the C++ runtime.
The `libraries` list adds to that set; leaving it empty keeps the standard libraries.
Refresh the `native-deps` import, update the VM, and open a new VM shell as described above.
Then retry the executable.

### Load native extensions in Python or Node.js

Python and Node.js from Nixpkgs use a loader from the Nix store.
Enabling `nix-ld` alone does not make its libraries available to native extensions loaded inside these interpreters.
After enabling it, pass the library path to the affected command inside the VM:

```console
LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" python your-script.py
```

Replace `python your-script.py` with your project's failing command, such as `node your-script.js` for Node.js.
For a Python virtual environment, activate it first.
The libraries must match the extension's requirements.

```{warning}
Keep `LD_LIBRARY_PATH` local to the affected command.
Setting it globally can make other Nix programs load incompatible libraries.
```

See the [nix-ld interpreter FAQ](https://github.com/nix-community/nix-ld/blob/2.0.6/README.md#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld) for this distinction.

### Use a packaged environment instead

You can also use one of these approaches:

- Use a Nixpkgs package for the tool, and configure the project to use that executable when it supports an existing installation.
- Use a language environment from Nixpkgs that includes the required packages and their native dependencies.
  For Python, [withPackages](https://nixos.org/manual/nixpkgs/stable/#python.withPackages) selects packages for one interpreter.
  This is a separate Python environment, not a repair applied to an existing pip virtual environment.
- Run the affected command in a container using a Linux distribution supported by the tool, with its documented runtime libraries installed.

Choose packages for the VM's architecture and check that their versions match the project's requirements.
After changing the environment, rerun the command that originally failed.
