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
    rebuiltVersionTest = verify "the upstream version test uses the rebuilt binary" (
      map toString rebuilt.tests.version.nativeBuildInputs == [ rebuilt.outPath ]
    ) defaultConfiguration;
  };
}
