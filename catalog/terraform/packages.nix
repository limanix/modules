{ version, system }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
        inherit (source) sha256;
      })
      {
        inherit system;
        config.allowUnfreePredicate = package: package.pname == "terraform";
      };
  terraform = packages.${release.package};
in
assert terraform.version == release.version;
{
  inherit terraform;
  inherit (release) endOfLife;
}
