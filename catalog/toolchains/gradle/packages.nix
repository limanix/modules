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
  gradle = release.packages.${release.package};
in
assert release.matches gradle.version;
{
  inherit gradle;
  inherit (release) endOfLife java;
}
