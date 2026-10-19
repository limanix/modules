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
  terraform = packages.${release.package};
in
assert release.matches terraform.version;
{
  inherit terraform;
  inherit (release) endOfLife;
}
