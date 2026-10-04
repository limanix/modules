# Harlequin

Installs Harlequin, a terminal SQL IDE, with its PostgreSQL adapter in the same
Python environment. DuckDB and SQLite adapters are included by Harlequin.
Catppuccin Mocha is the default theme.

```toml
[nixos]
modules = ["lmx:harlequin"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Harlequin and its PostgreSQL adapter come from the catalog's
[base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines. Run `harlequin --version` inside the VM to see
the installed application and adapters.

## Use

Connect to an existing PostgreSQL database inside the VM:

```console
harlequin --adapter postgres "postgresql://user@localhost:5432/database"
```

Harlequin uses the standard PostgreSQL `PG*` environment variables for
connection settings. The interface lets you browse the database catalog, edit
SQL and inspect query results. This module installs the client; select and
configure a PostgreSQL service separately if you need a database server in the
VM.

For a local SQLite file:

```console
harlequin --adapter sqlite ./database.sqlite
```

Run `harlequin --config` to create a personal connection profile. Harlequin
reads profiles from project TOML files, `~/.config/harlequin/config.toml` and
home-directory TOML files. The user configuration directory respects
`XDG_CONFIG_HOME`. Set `theme` in a personal profile or pass `--theme` to choose
another theme. The command-line theme takes precedence over the profile. See the
[Harlequin configuration guide](https://harlequin.sh/docs/config-file/) for
profile discovery and precedence.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Native project and user Harlequin TOML profiles; command-line options take precedence |
| Personal state | `~/.config/harlequin/config.toml`, home and project profiles |
| Integration | Packaged PostgreSQL adapter plus Harlequin's DuckDB and SQLite adapters |
| Services and capabilities | No database server or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| PostgreSQL connection fails | Check the guest-visible host, port, database, credentials and running server |
| Wrong connection profile | Inspect project and user configuration discovery before starting the SQL interface |
| BigQuery adapter | Not included by this module; installing gcloud separately does not add a Harlequin adapter |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| The module-owned package installs Harlequin with its PostgreSQL adapter | `eval.defaults`, `run.commands` |
| The installed CLI loads the PostgreSQL adapter and its connection options | `run.commands` |
| The module patch sets Mocha as the default without replacing personal or command-line themes | `run.theme` |
