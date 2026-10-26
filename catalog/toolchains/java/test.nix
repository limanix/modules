{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [ "jdk" ];
  serverSetup = ''export JAVA_TOOL_OPTIONS="-Duser.home=$HOME"'';
  check =
    { configuration, ... }:
    let
      inherit (configuration) config;
      lines = builtins.sort lib.versionOlder config.lmx.internal.java.versions;
      home = line: config.lmx.internal.java.packages.${line}.jdk.home;
      inherit (config.lmx.internal.java.packages.${lib.last lines}) jdk;
      registered =
        line:
        builtins.elem "L+ /usr/lib/jvm/openjdk-${line} - - - - ${home line}" config.systemd.tmpfiles.rules;
    in
    config.lmx.capabilities.jdk.package.outPath == jdk.outPath
    && config.environment.sessionVariables.JAVA_HOME == jdk.home
    && config.programs.nix-ld.enable
    && builtins.all registered lines;
  builds =
    { lines, toolsFor, ... }:
    {
      inherit (toolsFor (lib.last lines)) jdtls;
    };
  profileCommands = tools: {
    java = "${tools.jdk}/bin/java";
    javac = "${tools.jdk}/bin/javac";
    jdtls = "${tools.jdtls}/bin/jdtls";
  };
  commands =
    { line, profile, ... }:
    pkgs.runCommand "java-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME" project
      java -version 2>&1 | grep -F 'version "${line}'
      cd project
      printf 'public class Main { public static void main(String[] args) { System.out.println(40 + 2); } }\n' > Main.java
      javac Main.java
      test "$(java Main)" = 42
      touch "$out"
    '';
}
