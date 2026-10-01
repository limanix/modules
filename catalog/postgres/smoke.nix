{
  config,
  pkgs,
  version,
  evaluateStandalone,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs evaluateStandalone;
    directory = ./.;
    commands = {
      psql = "postgres";
      postgres = "postgres";
      pg_dump = "postgres";
      pg_restore = "postgres";
      pg_config = "postgres";
    };
  };
  commands = pkgs.runCommand "postgres-${version}-commands-smoke" { } ''
    for executable in ${tools.postgres}/bin/*; do
      test -x "${config.system.path}/bin/$(basename "$executable")-${version}"
    done
    ${config.system.path}/bin/psql-${version} --version | grep -F '${tools.postgres.version}'
    ${config.system.path}/bin/pg_config-${version} --version | grep -F '${tools.postgres.version}'
    ${config.system.path}/bin/postgres-${version} --version | grep -F '${tools.postgres.version}'
    test -d ${config.system.path}/share/postgresql
    touch "$out"
  '';
}
