{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers)
    profileFor
    verify
    installed
    selectedPackage
    ;
  releases = import ./releases.nix;
  toolsFor = configuration: line: configuration.config.lmx.internal.k9s.packages.${line};
  valid =
    configuration: line:
    import ./test/check.nix {
      inherit (configuration) config;
      tools = toolsFor configuration line;
      hasPackage = installed configuration;
    };
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: valid configuration line;
    runLine =
      { line, configuration }:
      (import ./test/smoke.nix {
        inherit pkgs profileFor;
        profile = profileFor configuration;
        version = line;
        tools = toolsFor configuration line;
        expectedTools = toolsFor configuration line;
        allVersionsConfiguration = configuration;
        includeShared = false;
      }).commands;
  };
  inherit (lineTests) lines configurations allConfiguration;
  rebuiltLines = builtins.filter (line: releases.versions.${line} ? buildSource) lines;
  localTests = import ./test/eval.nix {
    inherit verify rebuiltLines lib;
    toolsFor = line: toolsFor configurations.${line} line;
    defaultConfiguration = configurations.${lib.last lines};
  };
  newestTools = toolsFor allConfiguration (lib.last lines);
  sharedChecks = import ./test/smoke.nix {
    inherit pkgs profileFor;
    profile = profileFor allConfiguration;
    version = lib.last lines;
    tools = newestTools;
    expectedTools = newestTools;
    allVersionsConfiguration = allConfiguration;
    includeShared = true;
  };
in
{
  eval =
    lineTests.eval
    // localTests.evaluation
    // {
      allLines = verify "Selected lines retain their packages and the newest k9s command" (
        builtins.all (line: valid allConfiguration line) lines
        && selectedPackage allConfiguration newestTools.k9s
      ) allConfiguration;
    };
  run =
    lineTests.run
    // {
      allLines = sharedChecks.coexistence;
    }
    // lib.optionalAttrs (rebuiltLines != [ ]) {
      upstreamVersion = pkgs.runCommandLocal "k9s-rebuilt-upstream-version-tests" { } ''
        ${lib.concatMapStringsSep "\n" (
          line: "test -e ${(toolsFor configurations.${line} line).k9s.tests.version}"
        ) rebuiltLines}
        touch "$out"
      '';
    };
  builds = builtins.listToAttrs (
    lib.concatMap (
      line:
      let
        inherit ((toolsFor configurations.${line} line)) k9s;
      in
      [
        {
          name = "k9s-${line}";
          value = k9s;
        }
        {
          name = "k9s-upstream-version-${line}";
          value = k9s.tests.version;
        }
      ]
    ) rebuiltLines
  );
}
