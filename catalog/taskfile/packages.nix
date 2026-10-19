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
  task = packages.${release.package};
in
assert release.matches task.version;
{
  inherit task;
  inherit (release) endOfLife;
}
