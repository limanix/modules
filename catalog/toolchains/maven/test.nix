{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate installed profileFor;
  maven =
    configuration: line:
    configuration.config.lmx.internal.maven.packages.${line}.maven.override {
      jdk_headless = configuration.config.lmx.capabilities.jdk.package;
    };
  smoke =
    label: configuration:
    let
      inherit (configuration.config.lmx.capabilities.jdk) package;
    in
    pkgs.runCommand label { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      ${profileFor configuration}/bin/mvn --version > "$out"
      grep -F 'runtime: ${package.home}' "$out"
    '';
  java17 = evaluate [
    ./versions/3.nix
    ../java/versions/17.nix
  ];
  lineTests = import ../../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: installed configuration (maven configuration line);
    runLine = { line, configuration }: smoke "maven-${line}-commands" configuration;
  };
in
{
  inherit (lineTests) eval;
  run = lineTests.run // {
    java17 = smoke "maven-on-java-17" java17;
  };
  builds = {
    line-3 = maven lineTests.configurations."3" "3";
    java17 = maven java17 "3";
  };
}
