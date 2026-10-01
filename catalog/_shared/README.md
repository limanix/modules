# Public editor capabilities

The client loads `editor.nix` in every guest configuration, including an empty catalog selection.
It only declares options and never activates an editor or installs a tool.
The schema belongs to the client/catalog interface described in the [catalog contract](../../guides/catalog-contract.md).

`lmx.capabilities.editor.tools.<identity>` contains:

| Field | Type | Meaning |
|---|---|---|
| `package` | package, required | Package supplying the executable |
| `command` | string, required | Executable to run; catalog providers use its absolute store path |
| `args` | list of strings, default `[]` | Arguments for the executable |
| `languages` | list of strings, default `[]` | Consumer-independent language identities |

Tool keys identify tools, such as `gopls` and `rust-analyzer`, rather than editor configuration names.
Providers apply `lib.mkOverride (1000 - rank)` to the entire declaration, with the same rank used in `lib.setPrio (lib.meta.defaultPriority - rank)` for tool selection.
Ranks are non-negative and below 900.
An ordinary user definition overrides provider recommendations; conflicting declarations at equal precedence fail.
The provider installs the final selected declaration's package for the ordinary command.
Consumers use that final command and arguments without choosing a provider themselves.

`lmx.capabilities.editor.languages.<language>.parsers` is a required list of parser identities.
These additive declarations do not require a language server.
Consumers deduplicate parser requirements and map them to their parser configuration.
Third-party modules assign these public options without importing catalog files.
