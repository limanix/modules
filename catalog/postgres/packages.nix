{
  version,
  pinned,
  pkgs,
  ...
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  postgres = packages.${release.package};
in
assert release.matches postgres.version;
{
  inherit postgres;
  pgConfig = postgres.pg_config;
  inherit (release) endOfLife;
}
