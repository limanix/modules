# Harlequin

Installs Harlequin, a terminal SQL IDE, with its PostgreSQL adapter in the same
Python environment. DuckDB and SQLite adapters are included by Harlequin.

## Select

```toml
[nixos]
modules = ["lmx:harlequin"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change).

## Versions

Harlequin and its PostgreSQL adapter come from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines. Run `harlequin --version` inside the VM to see
the installed application and adapters.

## Use

Connect through the server's socket directory inside the VM. For the manual
instance from [PostgreSQL](../postgres/README.md#run-manually):

```console
harlequin --adapter postgres --host "$XDG_RUNTIME_DIR/postgresql-18" --dbname postgres
```

For its [system service](../postgres/README.md#run-as-a-system-service), use
`--host /run/postgresql --dbname "$(id -un)"`. Both connect as your VM user
without a password. Harlequin also reads the standard PostgreSQL `PG*`
environment variables. The interface lets you browse the database catalog, edit
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

## Theme

The default theme is Catppuccin in the guest's flavor. Harlequin refuses
Textual's terminal theme. With the default `system` flavor it stays Catppuccin
Mocha, with its own background.

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
