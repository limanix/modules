{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.postgres.versions);
  versions = map (line: config.lmx.internal.postgres.packages.${line}.postgres.version) selected;
  versioned = line: [
    "psql-${line}"
    "pg_ctl-${line}"
    "initdb-${line}"
  ];
in
{
  limanix.help.postgres = {
    title = "PostgreSQL ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "psql"
      "pg_ctl"
      "initdb"
      "createdb"
      "pg_dump"
      "pg_restore"
      "postgres"
      "pg_config"
    ]
    ++ lib.concatMap versioned selected;
    tips = [
      {
        label = "Init";
        text = "initdb -D ~/pgdata --auth-local=peer --auth-host=scram-sha-256";
      }
      {
        label = "Start";
        text = "pg_ctl -D ~/pgdata -l ~/pgdata.log -o \"-k $XDG_RUNTIME_DIR\" start";
      }
      {
        label = "Connect";
        text = "psql -h \"$XDG_RUNTIME_DIR\" -d postgres";
      }
      {
        label = "Stop";
        text = "pg_ctl -D ~/pgdata stop";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/postgres/README.html";
  };
}
