let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.oh-my-posh = {
    title = "Oh My Posh";
    summary = metadata.description;
    commands = [ "oh-my-posh" ];
    tips = [
      {
        label = "Settings";
        text = "POSH_THEME=~/my-theme.json in [env] replaces the managed settings.";
      }
      {
        label = "Debug";
        text = "oh-my-posh debug shows how long each part of the prompt takes.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/oh-my-posh";
  };
}
