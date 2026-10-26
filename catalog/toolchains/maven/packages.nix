{
  version,
  pinned,
  pkgs,
}:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  maven = release.packages.${release.package};
in
assert release.matches maven.version;
{
  inherit maven;
  inherit (release) endOfLife;
}
