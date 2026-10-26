{
  version,
  pinned,
  pkgs,
}:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  jdk = packages.${release.package};
in
assert release.matches jdk.version;
{
  inherit jdk;
  jdtls = packages.jdt-language-server.override { jdk = packages.jdk_headless; };
  inherit (packages) lombok;
  inherit (release) endOfLife;
}
