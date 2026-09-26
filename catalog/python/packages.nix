{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  python = packages.${release.package};
in
assert python.version == release.version;
{
  inherit python;
  inherit (python.pkgs) virtualenv;
  inherit (release) endOfLife;
}
