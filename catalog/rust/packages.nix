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
  rust = packages.${release.package}.packages.stable;
in
assert release.matches rust.rustc.version;
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
