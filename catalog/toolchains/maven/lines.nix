{
  name = "maven";
  title = "Maven";
  product = "Apache Maven";
  directory = ./.;
  main = "maven";
  packages = import ./packages.nix;
  line =
    {
      tools,
      priority,
      config,
      lib,
      ...
    }:
    {
      environment.systemPackages = [
        (lib.setPrio priority (
          tools.maven.override { jdk_headless = config.lmx.capabilities.jdk.package; }
        ))
      ];
    };
  commands = [ "mvn" ];
  tips = [
    {
      label = "Build";
      text = "mvn package";
    }
    {
      label = "Test";
      text = "mvn test";
    }
    {
      label = "Wrapper";
      text = "./mvnw runs the Maven version that the project pins.";
    }
  ];
  page = "modules/maven";
}
