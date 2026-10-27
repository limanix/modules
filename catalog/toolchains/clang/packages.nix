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
  clang = import ../../_shared/lib/compiler.nix { compiler = packages.${release.package}; };
  llvm = packages."llvmPackages_${version}";
in
assert release.matches clang.version;
{
  inherit clang;
  inherit (llvm) lldb clang-tools;
  inherit (release) endOfLife;
}
