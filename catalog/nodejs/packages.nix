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
  npm =
    if release ? npm then
      packages.callPackage ./npm.nix {
        nodejs = packages."nodejs-slim_${version}";
        inherit (release.npm) version hash;
      }
    else
      null;
  nodejs =
    if release ? npm then
      let
        slim = packages."nodejs-slim_${version}";
      in
      packages.${release.package}.override {
        nodejs-slim = slim // {
          inherit npm;
        };
      }
    else
      packages.${release.package};
in
assert release.matches nodejs.version;
{
  inherit nodejs;
  inherit (release) endOfLife;
}
// packages.lib.optionalAttrs (npm != null) { inherit npm; }
