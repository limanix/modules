{
  name = "gradle";
  title = "Gradle";
  directory = ./.;
  main = "gradle";
  single = true;
  packages = import ./packages.nix;
  line =
    {
      version,
      tools,
      priority,
      config,
      lib,
      ...
    }:
    let
      jdk = config.lmx.capabilities.jdk.package;
    in
    {
      assertions = [
        {
          assertion = lib.toInt (lib.versions.major jdk.version) <= tools.java;
          message = "gradle ${version} runs on Java ${toString tools.java} or older: choose a newer gradle line or an older java line in [toolchains]";
        }
      ];

      environment.systemPackages = [
        (lib.setPrio priority (tools.gradle.override { java = jdk; }))
      ];
    };
  commands = [ "gradle" ];
  tips = [
    {
      label = "Build";
      text = "gradle build";
    }
    {
      label = "Test";
      text = "gradle test";
    }
    {
      label = "Wrapper";
      text = "./gradlew runs the Gradle version that the project pins.";
    }
  ];
  page = "modules/gradle";
}
