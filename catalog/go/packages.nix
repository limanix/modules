{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  go = packages.${release.package};
in
assert go.version == release.version;
{
  inherit go;
  inherit (packages) gopls delve;
  inherit (release) endOfLife;
}
