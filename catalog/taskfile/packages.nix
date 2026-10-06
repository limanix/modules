{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  task = packages.${release.package};
in
assert task.version == release.version;
{
  inherit task;
  inherit (release) endOfLife;
}
