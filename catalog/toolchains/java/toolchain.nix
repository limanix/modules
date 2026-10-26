{
  name = "java";
  title = "Java";
  directory = ./.;
  main = "jdk";
  tool = "jdtls";
  parsers.java = [ "java" ];
  packages = import ./packages.nix;
  provider =
    { tools, ... }:
    {
      package = tools.jdtls;
      command = "${tools.jdtls}/bin/jdtls";
      args = [ "--jvm-arg=-javaagent:${tools.lombok}/share/java/lombok.jar" ];
      languages = [ "java" ];
    };
  systemPackages =
    {
      tools,
      lib,
      priority,
      ...
    }:
    [ (lib.setPrio priority tools.jdk) ];
  extra =
    { config, lib, ... }:
    let
      lines = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.java.versions);
      home = line: config.lmx.internal.java.packages.${line}.jdk.home;
      jdk = config.lmx.capabilities.jdk.package;
    in
    {
      lmx.capabilities.jdk.package =
        lib.mkDefault
          config.lmx.internal.java.packages.${lib.last lines}.jdk;
      environment.sessionVariables.JAVA_HOME = "${jdk.home or jdk}";
      programs.nix-ld.enable = lib.mkDefault true;
      systemd.tmpfiles.rules = [
        "d /usr/lib/jvm 0755 root root - -"
      ]
      ++ map (line: "L+ /usr/lib/jvm/openjdk-${line} - - - - ${home line}") lines;
    };
  commands = [
    "java"
    "javac"
    "jar"
    "jshell"
    "jdtls"
  ];
  tips = [
    {
      label = "Compile";
      text = "javac Main.java";
    }
    {
      label = "Run";
      text = "java Main";
    }
    {
      label = "Shell";
      text = "jshell";
    }
  ];
  page = "modules/java";
}
