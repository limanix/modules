{
  version,
  pinned,
  pkgs,
  ...
}:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  docker = packages.${release.package};
in
assert release.matches docker.version;
assert release.matches docker.moby.version;
{
  inherit docker;
  inherit (release) endOfLife;
}
