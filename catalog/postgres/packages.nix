{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  postgres = packages.${release.package};
in
assert postgres.version == release.version;
{
  inherit postgres;
  pgConfig = postgres.pg_config;
  inherit (release) endOfLife;
}
