# Node.js

Node.js with npm and npx.

```toml
[nixos]
modules = ["lmx:nodejs-24", "lmx:nodejs-26"]
```

| Selector                       | Node.js | npm     |
|--------------------------------|---------|---------|
| `lmx:nodejs` / `lmx:nodejs-26` | 26.9.0  | 12.1.0  |
| `lmx:nodejs-25`                | 25.9.0  | 11.12.1 |
| `lmx:nodejs-24`                | 24.20.0 | 11.19.0 |
| `lmx:nodejs-23`                | 23.11.0 | 10.9.2  |

`npm-24` and `npx-24` use Node.js 24, including project scripts.

Node.js 23 and 25 emit an end-of-support warning.
