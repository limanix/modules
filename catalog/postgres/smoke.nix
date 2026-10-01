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
    for executable in ${tools.postgres}/bin/*; do
      test -x "${profile}/bin/$(basename "$executable")-${version}"
    done
    ${profile}/bin/psql-${version} --version | grep -F '${tools.postgres.version}'
    ${profile}/bin/pg_config-${version} --version | grep -F '${tools.postgres.version}'
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
      pg_config = "postgres";
    };
  };
}
