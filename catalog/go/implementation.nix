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
  rank = builtins.length olderReleases;
  priority = lib.meta.defaultPriority - rank;

  versionedGo = pkgs.runCommand "go-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.go}/bin/go" "$out/bin/go-${version}"
  '';
in
{
  lmx.capabilities.languageSupport = {
    languages.go.parsers = [
      "go"
      "gomod"
      "gosum"
    ];
    tools.gopls = lib.mkOverride (1000 - rank) {
      package = lib.setPrio priority tools.gopls;
      command = "${tools.gopls}/bin/gopls";
      languages = [ "go" ];
    };
  };

  environment.systemPackages =
    map (lib.setPrio priority) [
      tools.go
      tools.delve
    ]
    ++ [
      versionedGo
      pkgs.gcc
    ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Go ${tools.go.version} no longer receives upstream security updates.";
}
