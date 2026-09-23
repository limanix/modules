version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.go.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedGo = pkgs.runCommand "go-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.go}/bin/go" "$out/bin/go-${version}"
  '';
in
{
  environment.systemPackages =
    map (lib.setPrio priority) [
      tools.go
      tools.gopls
      tools.delve
    ]
    ++ [ versionedGo ];

  warnings = lib.optional tools.endOfLife "Go ${tools.go.version} no longer receives upstream security updates.";
}
