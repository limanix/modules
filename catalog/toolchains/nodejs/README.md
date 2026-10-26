# Node.js

Installs Node.js with npm, npx, and the TypeScript/JavaScript language server.

## Select

```toml
[toolchains]
nodejs = "26"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). The
client guide describes the
[`[toolchains]` table](https://docs.limanix.dev/config/toolchains).

## Versions

The value selects one line:

| Value | Node.js | Notes |
| -- | -- | -- |
| `26` | 26.x | Recommended |
| `24` | 24.x |  |
| `22` | 22.x |  |

Lines marked `.x` come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive its patch releases with each catalog release.

Each line includes npm and npx for its Node.js version. Support status follows
the [Node.js release lifecycle](https://nodejs.org/en/about/previous-releases).
Selecting an end-of-life line prints a warning when the VM is built.

## Use

Inside the VM, run from a directory that contains `package.json`:

```console
npm install
npm run build
```

`npm install` installs the project's dependencies, and `npm run build` runs the
project's `build` script, if it defines one.

## Language server

The module installs
[typescript-language-server](https://github.com/typescript-language-server/typescript-language-server)
from the catalog's base Nixpkgs revision. Its packaged Node.js runtime and
fallback TypeScript compiler follow that revision independently of the selected
Node.js line. It declares the `typescript-language-server` tool with `--stdio`
under `lmx.capabilities.languageSupport` for JavaScript and TypeScript.
Selecting [AstroNvim](../../shell/astronvim/README.md) alongside Node.js enables
the declared server; installing Node.js alone does not enable an editor.
Projects may supply their own TypeScript version; see the server's
[configuration reference](https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md).

An ordinary user definition may replace the complete tool declaration, including
its package, command, and arguments. The final declared package is also
installed in the system profile.

## Native dependencies

npm packages built with `node-gyp` need Python, `make`, and a C/C++ compiler,
which this module does not install. Prebuilt programs and native addons in npm
packages can also need system libraries. See
[Handle native dependencies](https://docs.limanix.dev/inside/languages#native-libraries)
for both cases.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.languageSupport.tools.typescript-language-server`; JavaScript, TypeScript and TSX parsers |
| Personal state | Project `node_modules`, lock files and package-manager caches |
| Integration | Declares the server without enabling an editor; versioned npm/npx run the matching Node.js line |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| node-gyp build fails | Add Python, make, a compiler and required native libraries for that project |
| Unexpected compiler version | The server uses the project TypeScript version when configured; its fallback follows base Nixpkgs |
