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
  tools =
    if pkgs.lib.versionOlder (pkgs.lib.versions.majorMinor pkgs.go.version) version then
      (release.resolve "unstable").packages
    else
      packages;
in
assert release.matches go.version;
{
  inherit go;
  inherit (tools) gopls delve;
  inherit (release) endOfLife;
}
