let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.quarkus = {
    title = "Quarkus";
    summary = metadata.description;
    commands = [ "quarkus" ];
    tips = [
      {
        label = "Create";
        text = "quarkus create app org.acme:demo";
      }
      {
        label = "Dev mode";
        text = "quarkus dev";
      }
      {
        label = "Native";
        text = "quarkus build --native -Dquarkus.native.container-build=true";
      }
    ];
    guide = "https://docs.limanix.dev/modules/quarkus";
  };
}
