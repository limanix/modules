# Node.js

Installs Node.js with npm, npx, and the TypeScript/JavaScript language server.

```toml
[nixos]
modules = ["lmx:nodejs"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

`lmx:nodejs` recommends the catalog default.
An explicit `lmx:nodejs-LINE` selection replaces that recommendation, including when Cozy imports the default.

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

## Language server

The module installs [typescript-language-server](https://github.com/typescript-language-server/typescript-language-server) from the catalog's base Nixpkgs revision.
Its packaged Node.js runtime and fallback TypeScript compiler follow that revision independently of the selected Node.js line.
It declares the `typescript-language-server` tool with `--stdio` under `lmx.capabilities.languageSupport` for JavaScript and TypeScript.
Selecting [AstroNvim](../astronvim/README.md) alongside Node.js enables the declared server; installing Node.js alone does not enable an editor.
Projects may supply their own TypeScript version; see the server's [configuration reference](https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md).

An ordinary user definition may replace the complete tool declaration, including its package, command, and arguments.
The final declared package is also installed in the system profile.

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

## Configuration and integration

| Boundary | Contract |
|---|---|
| Public capability | `lmx.capabilities.languageSupport.tools.typescript-language-server`; JavaScript, TypeScript and TSX parsers |
| Personal state | Project `node_modules`, lock files and package-manager caches |
| Integration | Declares the server without enabling an editor; versioned npm/npx run the matching Node.js line |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
|---|---|
| node-gyp build fails | Add Python, make, a compiler and required native libraries for that project |
| Unexpected compiler version | The server uses the project TypeScript version when configured; its fallback follows base Nixpkgs |
| Several Node.js lines | Use versioned npm/npx when scripts need a specific interpreter |

## Guarantees

| Guarantee | Covered by |
|---|---|
| An explicit version replaces the default recommendation independently of import order | `checks/module.nix`: recommendation |
| Installs each selected Node.js line with npm, npx and their versioned commands | `check.nix`, `smoke.nix`: commands |
| Versioned npm and npx scripts run the matching Node.js interpreter | `smoke.nix`: commands |
| Selected lines coexist and the newest supplies unqualified commands | `tests.nix`: coexistence, `smoke.nix`: coexistence |
| Declares JavaScript/TypeScript/TSX parsers and the TypeScript language server package, command, arguments, and languages without enabling an editor | `check.nix`, `tests.nix`: providerSelection |
| A user tool declaration overrides the complete server declaration and installed package | `tests.nix`: userOverride, forceOverride; `smoke.nix`: providerOverride |
| The declared TypeScript language server starts and answers an LSP initialization request | `smoke.nix`: languageServer |
| Selecting a line recorded as end-of-life emits its version-specific warning | `check.nix` |
