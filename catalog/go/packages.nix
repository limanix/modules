{ version, pinned }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  go = packages.${release.package};
in
assert go.version == release.version;
{
  inherit go;
  inherit (packages) gopls delve;
  inherit (release) endOfLife;
}
