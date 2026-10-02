{
  coexistence,
  toolsFor,
  system,
  verify,
  defaultConfiguration,
  ...
}:
let
  releases = import ./releases.nix;
  release = releases.versions."0.40";
  source = releases.sources.${release.buildSource};
  builder = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
    inherit (source) sha256;
  }) { inherit system; };
  rebuilt = (toolsFor "0.40").k9s;
  applicationSource = releases.sources.${release.source};
  application = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${applicationSource.rev}.tar.gz";
    inherit (applicationSource) sha256;
  }) { inherit system; };
  unmodified = application.${release.package}.override {
    inherit (builder)
      stdenv
      buildGoModule
      installShellFiles
      writableTmpDirAsHomeHook
      testers
      ;
    k9s = rebuilt;
  };
in
{
  evaluation = {
    coexistence = coexistence [ "k9s" ];
    buildSource = verify "application and compiler use their declared source pins" (
      release.source == "legacy"
      && release.buildSource == "previous"
      && builtins.all (
        selected: !(selected ? buildSource) || builtins.hasAttr selected.buildSource releases.sources
      ) (builtins.attrValues releases.versions)
      && rebuilt.stdenv.drvPath == builder.stdenv.drvPath
      && rebuilt.passthru.go.version == builder.go.version
    ) defaultConfiguration;
    checkCache = verify "upstream tests reuse the build cache without reducing coverage" (
      rebuilt.checkFlags == (unmodified.checkFlags or [ ]) ++ [ "-trimpath" ]
      && rebuilt.buildPhase == unmodified.buildPhase
      && rebuilt.checkPhase == unmodified.checkPhase
      && rebuilt.doCheck == unmodified.doCheck
      && (rebuilt.subPackages or [ ]) == (unmodified.subPackages or [ ])
      && (rebuilt.excludedPackages or [ ]) == (unmodified.excludedPackages or [ ])
      && (rebuilt.preCheck or "") == (unmodified.preCheck or "")
      && (rebuilt.postCheck or "") == (unmodified.postCheck or "")
      && (rebuilt.nativeCheckInputs or [ ]) == (unmodified.nativeCheckInputs or [ ])
    ) defaultConfiguration;
    rebuiltVersionTest = verify "the upstream version test uses the rebuilt binary" (
      map toString rebuilt.tests.version.nativeBuildInputs == [ rebuilt.outPath ]
    ) defaultConfiguration;
  };
}
