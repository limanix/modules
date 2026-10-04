{ version, pinned }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  python = packages.${release.package};
in
assert python.version == release.version;
{
  inherit python;
  inherit (python.pkgs) virtualenv;
  inherit (release) endOfLife;
}
