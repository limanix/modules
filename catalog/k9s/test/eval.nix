{
  toolsFor,
  verify,
  defaultConfiguration,
  rebuiltLines,
  lib,
  ...
}:
let
  releases = import ../releases.nix;
in
{
  evaluation = lib.optionalAttrs (rebuiltLines != [ ]) {
    buildSource = verify "k9s: application and compiler retain their declared source pins" (builtins.all
      (
        line:
        let
          release = releases.versions.${line};
          tools = toolsFor line;
        in
        builtins.hasAttr release.buildSource releases.sources
        && tools.k9s.stdenv.drvPath == tools.buildStdenv.drvPath
        && tools.k9s.passthru.go.version == tools.buildGo.version
      )
      rebuiltLines
    ) defaultConfiguration;
    checkCache = verify "k9s: upstream tests retain coverage and matching build paths" (builtins.all (
      line:
      let
        tools = toolsFor line;
        rebuilt = tools.k9s;
      in
      rebuilt.checkFlags == (tools.unmodified.checkFlags or [ ]) ++ [ "-trimpath" ]
      && rebuilt.buildPhase == tools.unmodified.buildPhase
      && rebuilt.checkPhase == tools.unmodified.checkPhase
      && rebuilt.doCheck == tools.unmodified.doCheck
      && (rebuilt.subPackages or [ ]) == (tools.unmodified.subPackages or [ ])
      && (rebuilt.excludedPackages or [ ]) == (tools.unmodified.excludedPackages or [ ])
      && (rebuilt.preCheck or "") == (tools.unmodified.preCheck or "")
      && (rebuilt.postCheck or "") == (tools.unmodified.postCheck or "")
      && (rebuilt.nativeCheckInputs or [ ]) == (tools.unmodified.nativeCheckInputs or [ ])
    ) rebuiltLines) defaultConfiguration;
    rebuiltVersionTest = verify "k9s: upstream version check uses the rebuilt executable" (builtins.all
      (
        line:
        let
          rebuilt = (toolsFor line).k9s;
        in
        map toString rebuilt.tests.version.nativeBuildInputs == [ rebuilt.outPath ]
      )
      rebuiltLines
    ) defaultConfiguration;
  };
}
