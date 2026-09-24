{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  docker = packages.${release.package};
in
assert docker.version == release.version;
assert docker.moby.version == release.version;
{
  inherit docker;
  inherit (release) endOfLife;
}
