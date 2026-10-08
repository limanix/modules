let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.lazydocker = {
    title = "Lazydocker";
    summary = metadata.description;
    commands = [ "lazydocker" ];
    tips = [
      {
        label = "Shell";
        text = "Press E on a container to open a shell inside it.";
      }
      {
        label = "Keys";
        text = "Press ? for the key bindings.";
      }
      {
        label = "Check";
        text = "Run docker ps when Lazydocker cannot connect.";
      }
      {
        label = "Engine";
        text = "Select lmx:docker for a local Docker Engine.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/lazydocker/README.html";
  };
}
