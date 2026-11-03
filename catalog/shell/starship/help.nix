let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.starship = {
    title = "Starship";
    summary = metadata.description;
    commands = [ "starship" ];
    tips = [
      {
        label = "Settings";
        text = "A personal ~/.config/starship.toml replaces the managed settings.";
      }
      {
        label = "Explain";
        text = "starship explain describes each part of the prompt.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/starship";
  };
}
