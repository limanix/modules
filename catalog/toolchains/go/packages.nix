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
  inherit (release) packages;
  go = packages.${release.package};
in
assert release.matches go.version;
{
  inherit go;
  inherit (packages) gopls delve;
  inherit (release) endOfLife;
}
