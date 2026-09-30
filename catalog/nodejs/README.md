# Node.js

Installs Node.js with npm and npx.

```toml
[nixos]
modules = ["lmx:nodejs"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                      | Node.js | Notes       |
|-------------------------------|---------|-------------|
| `lmx:nodejs`, `lmx:nodejs-26` | 26.9.0  | Default     |
| `lmx:nodejs-25`               | 25.9.0  | End of life |
| `lmx:nodejs-24`               | 24.20.0 |             |
| `lmx:nodejs-23`               | 23.11.0 | End of life |

Each line includes npm and npx for its Node.js version.
Support status follows the [Node.js release lifecycle](https://nodejs.org/en/about/previous-releases).
Selecting an end-of-life line prints a warning when the VM is built.

## Use

Inside the VM, run from a directory that contains `package.json`:

```console
npm install
npm run build
```

`npm install` installs the project's dependencies, and `npm run build` runs the project's `build` script, if it defines one.

## Native dependencies

npm packages built with `node-gyp` need Python, `make`, and a C/C++ compiler, which this module does not install.
Prebuilt programs and native addons in npm packages can also need system libraries.
See [Handle native dependencies](../../guides/writing-modules.md#handle-native-dependencies) for both cases.

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:nodejs-24", "lmx:nodejs-26"]
```

Each line adds commands with its version: `node-24`, `npm-24`, and `npx-24` for Node.js 24.

```console
npm-24 install
npm-24 run build
```

The versioned `npm` and `npx` commands put their Node.js version first on `PATH`.
Scripts they run use that version.
`node`, `npm`, and `npx` come from the newest selected line.
