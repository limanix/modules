{
  profile,
  profileFor,
  pkgs,
  version,
  tools,
  newestTools,
  allVersionsConfiguration,
  includeShared,
  ...
}:
{
  commands = pkgs.runCommand "postgres-${version}-commands-smoke" { } ''
    for executable in ${tools.postgres}/bin/* ${tools.pgConfig}/bin/*; do
      test -x "${profile}/bin/$(basename "$executable")-${version}"
    done
    ${profile}/bin/psql-${version} --version | grep -F '${tools.postgres.version}'
    ${profile}/bin/pg_config-${version} --version | grep -F '${tools.postgres.version}'
    test "$(${profile}/bin/pg_config-${version} --bindir)" = "${tools.postgres}/bin"
    test -d "$(${profile}/bin/pg_config-${version} --includedir)"
    test -d "$(${profile}/bin/pg_config-${version} --includedir-server)"
    test -d "$(${profile}/bin/pg_config-${version} --libdir)"
    test -f "$(${profile}/bin/pg_config-${version} --pgxs)"
    ${profile}/bin/postgres-${version} --version | grep -F '${tools.postgres.version}'
    test -d ${profile}/share/postgresql
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands = {
      psql = "${newestTools.postgres}/bin/psql";
      postgres = "${newestTools.postgres}/bin/postgres";
      pg_dump = "${newestTools.postgres}/bin/pg_dump";
      pg_restore = "${newestTools.postgres}/bin/pg_restore";
      pg_config = "${newestTools.pgConfig}/bin/pg_config";
    };
  };
}
