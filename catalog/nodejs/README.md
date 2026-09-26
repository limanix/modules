# Node.js

Installs Node.js, npm, and npx inside the VM.

## Enable

Add a Node.js selector to the existing `nixos.modules` list, keeping the other modules your VM needs:

```toml
[nixos]
modules = ["lmx:nodejs"]
```

Follow [Use catalog modules](../../guides/using-modules.md) to apply the configuration from your Mac and enter the VM.

## Versions

| Selector | Node.js |
|----------|---------|
| `lmx:nodejs` / `lmx:nodejs-26` | 26.9.0 |
| `lmx:nodejs-25` | 25.9.0 |
| `lmx:nodejs-24` | 24.20.0 |
| `lmx:nodejs-23` | 23.11.0 |

The unversioned selector uses Node.js 26 in this catalog revision.
Each selection includes npm and npx for that Node.js toolchain.
The catalog marks Node.js 23 and 25 as end of life and emits a warning when either is selected.

## Use

Inside the VM, run from your project directory containing `package.json`:

```console
npm install
```

If the project defines a `build` script, run it with:

```console
npm run build
```

`npm install` installs the project's dependencies.
`npm run build` runs the command defined by its `build` script.

## Native dependencies

Dependencies built with `node-gyp` need Python, GNU Make, and a C/C++ compiler, which this module does not install.
Downloaded executables and native addons may also need runtime libraries.
See [Use native dependencies](../../guides/native-dependencies.md) for build tools, library discovery, and running prebuilt code on NixOS.

## Use several versions

Select the required versions together:

```toml
[nixos]
modules = ["lmx:nodejs-24", "lmx:nodejs-26"]
```

After updating the VM from your Mac, use the versioned npm command inside the VM to work with a specific toolchain:

```console
npm-24 install
npm-24 run build
```

Each selection provides `node-<version>`, `npm-<version>`, and `npx-<version>`, such as `node-24`, `npm-24`, and `npx-24`.
The npm and npx wrappers put the matching Node.js toolchain at the front of `PATH`, which is inherited by project scripts.
The highest selected version takes priority for the ordinary `node`, `npm`, and `npx` commands.
