{
  name = "postgres";
  title = "PostgreSQL";
  directory = ./.;
  main = "postgres";
  priorityOffset = 1;
  packages = import ./packages.nix;
  line =
    {
      version,
      tools,
      pkgs,
      lib,
      priority,
      ...
    }:
    {
      environment.systemPackages = [
        (lib.setPrio priority tools.postgres)
        (lib.setPrio priority tools.pgConfig)
        (pkgs.runCommandLocal "postgres-${version}-commands" { nativeBuildInputs = [ pkgs.makeWrapper ]; }
          ''
            mkdir -p "$out/bin"
            for command in "${tools.postgres}/bin/"* "${tools.pgConfig}/bin/"*; do
              makeWrapper "$command" "$out/bin/$(basename "$command")-${version}"
            done
          ''
        )
      ];

      environment.pathsToLink = [ "/share/postgresql" ];
    };
  commands = [
    "psql"
    "pg_ctl"
    "initdb"
    "createdb"
    "pg_dump"
    "pg_restore"
    "postgres"
    "pg_config"
  ];
  versioned = line: [
    "psql-${line}"
    "pg_ctl-${line}"
    "initdb-${line}"
  ];
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
  page = "modules/postgres";
}
