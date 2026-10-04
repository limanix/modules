{ version, pinned }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
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
assert nodejs.version == release.version;
{
  inherit nodejs;
  inherit (release) endOfLife;
}
// packages.lib.optionalAttrs (npm != null) { inherit npm; }
