version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) pins;
  tools = import ./packages.nix {
    inherit version pinned pkgs;
  };

  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  priority = lib.meta.defaultPriority - 1 - builtins.length olderLines;

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
  lmx.pins = pins;
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
