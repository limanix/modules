# PostgreSQL

Installs the PostgreSQL server and command-line tools for manual use inside the VM.
You choose where to store the data and when to start or stop the server.
The module does not initialize a database or enable a service.
For automatic startup, see [Run as a system service](#run-as-a-system-service).

```toml
[nixos]
modules = ["lmx:postgres"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

| Selector                          | PostgreSQL | Notes   |
|-----------------------------------|------------|---------|
| `lmx:postgres`, `lmx:postgres-18` | 18.6       | Default |
| `lmx:postgres-17`                 | 17.11      |         |
| `lmx:postgres-16`                 | 16.15      |         |

Upstream support dates are listed in the [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/).

Each line adds commands with a version suffix, including `postgres-18`, `initdb-18`, `pg_ctl-18`, `psql-18`, `pg_dump-18`, and `pg_restore-18`.
Inside the VM, `postgres --version` shows the installed server version.

## Run manually

Run these commands inside the VM as its regular user.
Choose a data directory you can write to.
This example uses `$HOME`, which LimaNix stores on the Mac and mounts into the VM; change `pg_root` to use another location.
The socket uses the VM's runtime directory independently of the data location.

```console
pg_root="$HOME/.local/share/postgresql/18"
pg_socket="$XDG_RUNTIME_DIR/postgresql-18"
mkdir -p "$pg_root"
initdb-18 -D "$pg_root/data" --auth-local=peer --auth-host=scram-sha-256
```

Run `initdb` only once for a new instance.
It creates a database superuser with your VM user's name and a database named `postgres`.
Before the first start, open `$pg_root/data/postgresql.conf` inside the VM.
Replace the generated `#listen_addresses = 'localhost'` line with:

```text
listen_addresses = ''
```

This disables TCP connections.
Keep a single active `listen_addresses` line and edit that same line in the steps below.
If you previously appended another assignment at the end of the file, remove the duplicate: PostgreSQL uses the last assignment for a repeated setting.

Start the server and connect through its Unix socket:

```console
mkdir -p "$pg_socket"
pg_ctl-18 -D "$pg_root/data" -l "$pg_root/server.log" \
  -o "-k '$pg_socket'" start
psql-18 -h "$pg_socket" -d postgres
```

The connection uses your role and authenticates your operating-system user through the socket; no `sudo` or password is needed.
Run `\q` to leave `psql`, then stop the server when finished:

```console
pg_ctl-18 -D "$pg_root/data" stop
```

Stopping the server preserves its data.
Set `pg_root` and `pg_socket` again whenever you open a new shell.
After restarting the VM, recreate the socket directory and run the start command.
Do not repeat `initdb` for an existing instance.
See [Storage and data](https://limanix.dev/categories/client/virtual-machines.html#storage-and-data) for what happens to each storage location when the VM is deleted.
See the PostgreSQL references for [initialization](https://www.postgresql.org/docs/18/app-initdb.html) and [server control](https://www.postgresql.org/docs/18/app-pg-ctl.html).

## Configure the instance

For the manually initialized instance, edit these files inside the VM:

| File | Controls |
|------|----------|
| `$pg_root/data/postgresql.conf` | Server settings, including `listen_addresses`, `port`, and memory limits |
| `$pg_root/data/pg_hba.conf` | Which connections are allowed and how they authenticate |

These are PostgreSQL configuration files, not shell scripts; shell variables such as `$HOME` are not expanded in them.
The start command's `-k` option selects the socket directory and overrides `unix_socket_directories` from the configuration file.

After changing authentication rules or settings that support reload:

```console
pg_ctl-18 -D "$pg_root/data" reload
```

Changes to `listen_addresses`, `port`, or the socket directory require a restart: stop the server and run the start command again.
See [server settings](https://www.postgresql.org/docs/18/config-setting.html) and [authentication rules](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html).

### Enable TCP inside the VM

In `psql`, connected through the socket, run `\password` to set a password for your database role.
Then replace the existing active `listen_addresses` line in `postgresql.conf` with the value below.
Set `port` by editing its existing entry, removing the leading `#` if needed:

```text
listen_addresses = 'localhost'
port = 5432
```

The earlier `initdb --auth-host=scram-sha-256` command configures password authentication for loopback TCP connections.
Restart the server, then connect from inside the VM:

```console
psql-18 -h localhost -p 5432 -U "$(id -un)" -d postgres -W
```

This listens only on the VM's loopback interfaces; it does not expose PostgreSQL on the VM's network address.
For access from the Mac, follow [Connect from the Mac](#connect-from-the-mac).

### Create an application database

For a database owned by your current role:

```console
createdb-18 -h "$pg_socket" app
psql-18 -h "$pg_socket" -d app
```

## Several versions

Select several lines to install them side by side:

```toml
[nixos]
modules = ["lmx:postgres-16", "lmx:postgres-17", "lmx:postgres-18"]
```

Use the versioned commands to choose a line:

```console
postgres-16 --version
postgres-17 --version
postgres-18 --version
```

Commands without a suffix, such as `postgres` and `psql`, come from the newest selected line.
Give each running instance its own data and socket directories.
If you enable TCP, use a separate port for each instance.

## Run as a system service

To let NixOS initialize PostgreSQL and start it when the VM boots, configure `services.postgresql` in a [custom module](../../guides/writing-modules.md).
This example also creates a database and role named after the VM user, allowing that user to connect without `sudo` or a password.
It accepts connections only from inside the VM by default; [Mac access](#connect-from-the-mac) requires additional configuration.
Save it on the Mac as `modules/postgres-service/default.nix`:

```nix
{ config, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = [ config.limanix.user.name ];
    ensureUsers = [
      {
        name = config.limanix.user.name;
        ensureDBOwnership = true;
      }
    ];
  };
}
```

On the Mac, import it:

```console
limanix modules add postgres-service ./modules/postgres-service
```

Add `third-party:postgres-service` to `nixos.modules` and [apply the configuration](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).
The service module installs its own PostgreSQL package; `lmx:postgres` is only needed if you also want the catalog's versioned commands.
`services.postgresql.package` selects a package from the base Nixpkgs revision independently of the catalog selector, so its patch version can differ.
Change `pkgs.postgresql_18` to `pkgs.postgresql_17` or `pkgs.postgresql_16` to select another service version.
When catalog lines are also selected, commands without a suffix come from the newest selected catalog line, even if the service uses a different major version.
For example, `lmx:postgres-16` with the service on 18 provides `psql` from 16; the service still runs PostgreSQL 18.
Select `lmx:postgres-18` as well to use `psql-18` explicitly.

Inside the VM, inspect the service and connect to the database created for your user:

```console
systemctl status postgresql
psql -h /run/postgresql -d "$(id -un)"
```

The service stores data in `/var/lib/postgresql/<major>` on the VM disk by default.
Configure its data location with `services.postgresql.dataDir`, server settings with `services.postgresql.settings`, and connection rules with `services.postgresql.authentication`.
This is a separate instance from the manual example; enabling it does not move or import that instance's data.
For changes to an imported module, follow [Replace an imported module](https://limanix.dev/categories/client/modules.html#replace-an-imported-module).

## Connect from the Mac

Follow [Open a service port](https://limanix.dev/categories/client/networking.html#open-a-service-port) for the VM address and firewall configuration.
For PostgreSQL, use TCP port `5432` and the settings below.
Connect to the VM's `ADDRESS`; `localhost:5432` on the Mac does not reach PostgreSQL in the VM.

### Allow the Mac in PostgreSQL

In the examples below, replace `MAC_IP` with the Mac's source IPv4 address as seen by the VM, not the VM's own address.
`/32` allows that single address.
If you do not know it, first enable the listener and firewall without the new authentication rule, then try connecting from the Mac.
For this probe, omit `-W` from the connection command below.
PostgreSQL's `no pg_hba.conf entry for host "..."` error reports the source address to use.
Then add the rule with that address and reload the manual instance, or reimport the service module and apply the configuration again.

For a **manual instance**, replace the existing active `listen_addresses` line in `$pg_root/data/postgresql.conf` inside the VM.
Set `port` by editing its existing entry, removing the leading `#` if needed:

```text
listen_addresses = '*'
port = 5432
```

Add this line to `$pg_root/data/pg_hba.conf`, keeping the existing local rules:

```text
host all all MAC_IP/32 scram-sha-256
```

For the **system service**, add these settings to the existing `services.postgresql` block in `modules/postgres-service/default.nix` on the Mac:

```nix
enableTCPIP = true;
authentication = ''
  host all all MAC_IP/32 scram-sha-256
'';
```

NixOS keeps its default local authentication rules and adds this rule before them.
Edit the module, rather than the service's generated `pg_hba.conf`.
Reimport the changed module on the Mac before applying the configuration:

```console
limanix modules remove postgres-service
limanix modules add postgres-service ./modules/postgres-service
```

### Open the guest firewall and apply

Follow [Open a service port](https://limanix.dev/categories/client/networking.html#open-a-service-port) on the Mac, adding `5432` to the existing TCP list in `limanix.toml` and retaining any other ports:

```toml
[network.ports]
tcp = [5432]
```

Apply the configuration from the Mac:

```console
limanix update --config ./limanix.toml
```

The update restarts the VM.
The system service starts automatically; for a manual instance, open a new guest shell, set `pg_root` and `pg_socket` again, and repeat the [start commands](#run-manually).
The existing data directory is reused; do not run `initdb` again.

### Set a password and connect

Inside the VM, connect through the Unix socket using the command for your manual instance or system service above.
In `psql`, run `\password` to set a password for the connected role, then `\q`.
Keep the password out of the Nix module and TOML file.

On the Mac, run `limanix list` and read the VM's current `ADDRESS`.
With `psql` installed on the Mac, connect using that address:

```console
psql -h <guest-ip> -p 5432 -U <vm-user> -d <database> -W
```

Replace `<vm-user>` with the VM user's name, which may differ from your Mac username.
For the manual example, use `postgres` as `<database>`; for the service example, use the VM user's name.
Use the same host, port, database, user, and password in a graphical PostgreSQL client.
If the connection fails, follow [Check a connection in order](https://limanix.dev/categories/client/networking.html#check-a-connection-in-order); a refusal or timeout must be resolved before PostgreSQL authentication can run.
If the Mac's source address changes, update the authentication rule as well.

## Upgrades

Use the same major version to initialize and run a data directory.
Moving existing data to another major version requires a [PostgreSQL upgrade](https://www.postgresql.org/docs/18/upgrading.html).
Changing a service's major version changes its default data directory and initializes a new instance if that directory is empty; it does not migrate the old databases.

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the selected PostgreSQL tools and version-suffixed wrappers for all their executables | `check.nix`, `smoke.nix`: commands |
| Links PostgreSQL shared data into the profile | `check.nix`, `smoke.nix`: commands |
| Selected lines coexist; the newest supplies ordinary commands ahead of a separately enabled service package | `checks/default.nix`: multiVersion, `checks/contracts.nix`, `smoke.nix`: coexistence |
| Selecting this module alone does not enable a database service or initialize a data directory | `checks/contracts.nix` |
