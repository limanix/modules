{
  profile,
  profileFor,
  pkgs,
  version,
  allVersionsConfiguration,
  includeShared,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
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
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    directory = ./.;
    commands = {
      psql = "postgres";
      postgres = "postgres";
      pg_dump = "postgres";
      pg_restore = "postgres";
      pg_config = "pgConfig";
    };
  };
}
