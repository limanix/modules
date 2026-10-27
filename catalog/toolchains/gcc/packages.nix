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
  gcc = import ../../_shared/lib/compiler.nix { compiler = packages.${release.package}; };
in
assert release.matches gcc.version;
{
  inherit gcc;
  inherit (gcc) bintools;
  clangd = packages.clang-tools;
  inherit (release) endOfLife;
}
