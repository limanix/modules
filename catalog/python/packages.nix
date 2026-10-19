{
  version,
  pinned,
  pkgs,
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  python = packages.${release.package};
in
assert release.matches python.version;
{
  inherit python;
  inherit (python.pkgs) virtualenv;
  inherit (release) endOfLife;
}
