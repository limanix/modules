{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  postgres = packages.${release.package};
in
assert postgres.version == release.version;
{
  inherit postgres;
  pgConfig = postgres.pg_config;
  inherit (release) endOfLife;
}
