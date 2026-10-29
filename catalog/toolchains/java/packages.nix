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
  jdtlsRuntime = packages.jdt-language-server.override { jdk = packages.jdk_headless; };
in
assert release.matches jdk.version;
{
  inherit jdk jdtlsRuntime;
  jdtls = packages.writeShellScriptBin "jdtls" ''
    exec ${packages.python3}/bin/python3 ${./jdtls.py} ${jdtlsRuntime}/bin/jdtls "$@"
  '';
  inherit (packages) lombok;
  inherit (release) endOfLife;
}
