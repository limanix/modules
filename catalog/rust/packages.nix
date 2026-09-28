{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  rust = packages.${release.package}.packages.stable;
in
assert rust.rustc.version == release.version;
{
  inherit (rust)
    rustc
    cargo
    rustfmt
    clippy
    ;
  inherit (packages) rust-analyzer;
  inherit (release) endOfLife;
}
