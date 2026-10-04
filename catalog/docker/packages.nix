{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  docker = packages.${release.package};
in
assert docker.version == release.version;
assert docker.moby.version == release.version;
{
  inherit docker;
  inherit (release) endOfLife;
}
