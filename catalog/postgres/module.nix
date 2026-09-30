version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.postgres.version
  ) releases;
  priority = lib.meta.defaultPriority - 1 - builtins.length olderReleases;

  versionedPostgres =
    pkgs.runCommand "postgres-${version}-commands"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out/bin"
        for command in "${tools.postgres}/bin/"*; do
          makeWrapper "$command" "$out/bin/$(basename "$command")-${version}"
        done
      '';
in
{
  environment.systemPackages = [
    (lib.setPrio priority tools.postgres)
    versionedPostgres
  ];

  environment.pathsToLink = [ "/share/postgresql" ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "PostgreSQL ${tools.postgres.version} no longer receives upstream security updates.";
}
