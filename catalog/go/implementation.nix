version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version pinned;
  };

  catalog = import ./releases.nix;
  source = catalog.sources.${catalog.versions.${version}.source};
  releases = builtins.attrValues catalog.versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.go.version
  ) releases;
  rank = builtins.length olderReleases;
  priority = lib.meta.defaultPriority - rank;

  versionedGo = pkgs.runCommandLocal "go-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.go}/bin/go" "$out/bin/go-${version}"
  '';
in
{
  assertions = [
    {
      assertion = rank >= 0 && rank < 100;
      message = "go: provider recommendation rank must be between 0 and 99";
    }
  ];

  lmx = {
    pins.${source.rev} = source.sha256;
    internal.go.packages.${version} = tools;

    capabilities.languageSupport = {
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
