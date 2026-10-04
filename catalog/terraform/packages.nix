{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  terraform = packages.${release.package};
in
assert terraform.version == release.version;
{
  inherit terraform;
  inherit (release) endOfLife;
}
