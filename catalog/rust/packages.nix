{ version, pinned }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
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
