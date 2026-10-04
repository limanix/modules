# One temporary, non-root database. Every command comes from the selected profile.
{
  pkgs,
  profile,
  line,
}:
pkgs.runCommand "postgres-${line}-native-lifecycle"
  {
    nativeBuildInputs = [ profile ];
    preCheck = ''
      export HOME="$TMPDIR/home"
      export PGDATA="$TMPDIR/data"
      export PGHOST="$TMPDIR/socket"
      export PGUSER="$(id -un)"
      mkdir -p "$HOME" "$PGHOST"
      initdb-${line} -D "$PGDATA" --locale=C --encoding=UTF8 --auth-local=trust --auth-host=scram-sha-256
      pg_ctl-${line} -D "$PGDATA" -l "$TMPDIR/postgres.log" \
        -o "-k $PGHOST -c listen_addresses=" -t 30 -w start
    '';
    postCheck = ''
      if test -f "$TMPDIR/data/postmaster.pid"; then
        pg_ctl-${line} -D "$TMPDIR/data" -m fast -t 30 -w stop
      fi
    '';
  }
  ''
      if test "$(id -u)" -eq 0; then
        echo "PostgreSQL lifecycle requires a non-root Nix builder" >&2
        exit 1
      fi
      cleanup() {
        status=$?
        trap - EXIT
        if ! runHook postCheck; then status=1; fi
        exit "$status"
      }
      trap cleanup EXIT
      runHook preCheck
      psql-${line} -X -v ON_ERROR_STOP=1 -d postgres <<'SQL'
        CREATE TABLE module_probe (answer integer NOT NULL);
        INSERT INTO module_probe VALUES (42);
    SQL
      test "$(psql-${line} -X -v ON_ERROR_STOP=1 -d postgres -tAc 'SELECT answer FROM module_probe')" = 42
      runHook postCheck
      trap - EXIT
      touch "$out"
  ''
