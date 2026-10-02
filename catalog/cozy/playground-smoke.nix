{ pkgs }:
let
  python = pkgs.python314.withPackages (packages: [ packages.psycopg ]);
in
pkgs.runCommand "cozy-notes-playground"
  {
    nativeBuildInputs = [
      # Runtime tools only; the default build input selects development files.
      (pkgs.lib.getBin pkgs.postgresql)
      python
    ];
  }
  ''
    export HOME="$TMPDIR/home" PGDATA="$TMPDIR/postgres" PGHOST="$TMPDIR/socket"
    mkdir -p "$HOME" "$PGHOST"
    initdb --no-locale --encoding=UTF8 --auth=trust > "$TMPDIR/initdb.log"
    pg_ctl -l "$TMPDIR/postgres.log" -o "-k '$PGHOST' -c listen_addresses=" -w start
    trap 'pg_ctl -m immediate -w stop > /dev/null' EXIT
    createdb cozy
    export DATABASE_URL="dbname=cozy host=$PGHOST"
    python ${./playground-smoke.py} ${./playground}/app.py
    touch "$out"
  ''
