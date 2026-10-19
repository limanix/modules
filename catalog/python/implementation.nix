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
  # Lines rank by their numbers: lines from the base or unstable record no exact version.
  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  rank = builtins.length olderLines;
  priority = lib.meta.defaultPriority - rank;
  runtimePython = import ./runtime-package.nix {
    inherit lib;
    python = lib.setPrio priority tools.python;
  };

  versionedPython = pkgs.runCommandLocal "python-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.python.interpreter}" "$out/bin/python-${version}"
  '';
in
{
  assertions = [
    {
      assertion = rank >= 0 && rank < 100;
      message = "python: provider recommendation rank must be between 0 and 99";
    }
  ];

  lmx = {
    inherit pins;
    internal.python.packages.${version} = tools;

    capabilities.languageSupport = {
      languages.python.parsers = [ "python" ];
      tools.pyright = lib.mkOverride (1000 - rank) {
        package = lib.setPrio priority pkgs.pyright;
        command = "${pkgs.pyright}/bin/pyright-langserver";
        args = [ "--stdio" ];
        languages = [ "python" ];
      };
    };
  };

  environment.systemPackages = [
    runtimePython
    (lib.setPrio priority tools.virtualenv)
    versionedPython
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Python ${tools.python.version} no longer receives upstream security updates.";
}
