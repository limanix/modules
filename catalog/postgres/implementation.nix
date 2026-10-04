version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  releases = import ./releases.nix;
  source = releases.sources.${releases.versions.${version}.source};
  tools = import ./packages.nix {
    inherit version pinned;
  };

  releaseValues = builtins.attrValues releases.versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.postgres.version
  ) releaseValues;
  priority = lib.meta.defaultPriority - 1 - builtins.length olderReleases;

  versionedPostgres =
    pkgs.runCommandLocal "postgres-${version}-commands"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out/bin"
        for command in "${tools.postgres}/bin/"* "${tools.pgConfig}/bin/"*; do
          makeWrapper "$command" "$out/bin/$(basename "$command")-${version}"
        done
      '';
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.postgres.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.postgres)
    (lib.setPrio priority tools.pgConfig)
    versionedPostgres
  ];

  environment.pathsToLink = [ "/share/postgresql" ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "PostgreSQL ${tools.postgres.version} no longer receives upstream security updates.";
}
