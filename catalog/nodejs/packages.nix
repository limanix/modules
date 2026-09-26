{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  nodejs =
    if release ? npm then
      let
        slim = packages."nodejs-slim_${version}";
      in
      packages.${release.package}.override {
        nodejs-slim = slim // {
          npm = packages.callPackage ./npm.nix {
            nodejs = slim;
            inherit (release.npm) version hash;
          };
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
