# Shared catalog contracts

`_shared` has no module selector. Public Nix files declare capabilities; private
files and pure data support the modules that import them. No shared file
activates applications by being present in the catalog.

| File or directory | Role | Loaded by |
| -- | -- | -- |
| `languageSupport.nix` | Public provider/consumer schema | Client in every generated guest |
| `internal/` | Private coordination declarations | Catalog modules that need them |
| `palette.toml` | Catppuccin Mocha color values | Terminal modules that use the palette |

## Public language support capabilities

The client loads `languageSupport.nix` in every guest configuration, including
an empty catalog selection. It only declares options and never activates an
editor or installs a tool. The schema belongs to the client/catalog interface
described in the [catalog contract](../../guides/catalog-contract.md).

`lmx.capabilities.languageSupport.tools.<identity>` contains:

| Field | Type | Meaning |
| -- | -- | -- |
| `package` | package, required | Package supplying the executable |
| `command` | string, required | Executable to run; catalog providers use its absolute store path |
| `args` | list of strings, default `[]` | Arguments for the executable |
| `languages` | list of strings, default `[]` | Consumer-independent language identities |

Tool keys identify tools, such as `gopls` and `rust-analyzer`, rather than
editor configuration names. Providers apply `lib.mkOverride (1000 - rank)` to
the entire declaration, with the same rank used in
`lib.setPrio (lib.meta.defaultPriority - rank)` for tool selection. Ranks are
non-negative and below 900. An ordinary user definition overrides provider
recommendations; conflicting declarations at equal precedence fail. The provider
installs the final selected declaration's package for the ordinary command.
Consumers use that final command and arguments without choosing a provider
themselves.

`lmx.capabilities.languageSupport.languages.<language>.parsers` is a required
list of parser identities. These additive declarations do not require a language
server. Consumers deduplicate parser requirements and map them to their parser
configuration. Third-party modules assign these public options without importing
catalog files.

## Palette

`palette.toml` is data, not a module or public NixOS option area. Zsh's managed
prompt, tmux, Lazygit and Yazi read its Mocha values. Each consumer owns how the
palette maps to its interface and how users override it. AstroNvim, Posting and
Harlequin select their application's packaged Mocha theme. Changing a shared
value requires checking every consumer's generated configuration.

## Corner cases

| Case | Contract |
| -- | -- |
| No catalog modules selected | Public declarations remain available with empty defaults |
| Third-party provider only | It can assign public options without importing catalog paths |
| Two tool declarations at the same priority | Different complete declarations conflict |
| User declaration overrides a provider | The selected command, arguments and package change together |
| Shared palette exists | Optional consumers remain inactive until selected |

## Guarantees

Public declarations do not install tools or activate editors. The shared schema
supports parser-only language declarations and complete user tool overrides.
`checks/common.nix` checks the public schema and provider/consumer cases; module
and integration checks exercise consumers.
