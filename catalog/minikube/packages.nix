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
  minikube = packages.${release.package};
in
assert release.matches minikube.version;
{
  inherit minikube;
  inherit (release) endOfLife;
}
