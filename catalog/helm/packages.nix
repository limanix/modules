{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  helm = packages.${release.package};
in
assert helm.version == release.version;
{
  inherit helm;
  inherit (release) endOfLife;
}
