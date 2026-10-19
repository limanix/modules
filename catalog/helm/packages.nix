{
  version,
  pinned,
  pkgs,
  ...
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  helm = packages.${release.package};
in
assert release.matches helm.version;
{
  inherit helm;
  inherit (release) endOfLife;
}
