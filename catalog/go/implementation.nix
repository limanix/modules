version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version pinned pkgs;
  };

  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) pins;
  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  rank = builtins.length olderLines;
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
    inherit pins;
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
