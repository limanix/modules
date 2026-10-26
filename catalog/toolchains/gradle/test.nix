{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate installed profileFor;
  gradle =
    configuration: line:
    configuration.config.lmx.internal.gradle.packages.${line}.gradle.override {
      java = configuration.config.lmx.capabilities.jdk.package;
    };
  smoke =
    label: configuration:
    let
      inherit (configuration.config.lmx.capabilities.jdk.package) version;
    in
    pkgs.runCommand label { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      ${profileFor configuration}/bin/gradle --version > "$out"
      grep -E 'Launcher JVM: +${lib.head (lib.splitString "+" version)}' "$out"
    '';
  java25 = evaluate [
    ./versions/9.nix
    ../java/versions/25.nix
  ];
  lineTests = import ../../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: installed configuration (gradle configuration line);
    runLine = { line, configuration }: smoke "gradle-${line}-commands" configuration;
  };
in
{
  inherit (lineTests) eval;
  run = lineTests.run // {
    java25 = smoke "gradle-9-on-java-25" java25;
  };
  builds = {
    line-8 = (gradle lineTests.configurations."8" "8").unwrapped;
    line-9 = (gradle lineTests.configurations."9" "9").unwrapped;
    java25 = (gradle java25 "9").unwrapped;
  };
  fails = {
    twoLines = {
      modules = map (line: ./versions + "/${line}.nix") lineTests.lines;
      message = "gradle: select one line";
    };
    java25 = {
      modules = [
        ./versions/8.nix
        ../java/versions/25.nix
      ];
      message = "gradle 8 runs on Java 24 or older: choose a newer gradle line or an older java line in [toolchains]";
    };
  };
}
