{ version, pinned, ... }:
let
  releases = import ./releases.nix;
  release = releases.versions.${version};
  source = releases.sources.${release.source};
  packages = pinned.${source.rev};
  minikube = packages.${release.package};
in
assert minikube.version == release.version;
{
  inherit minikube;
  inherit (release) endOfLife;
}
