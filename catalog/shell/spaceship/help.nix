let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.spaceship = {
    title = "Spaceship";
    summary = metadata.description;
    tips = [
      {
        label = "Settings";
        text = "~/.spaceshiprc.zsh changes any setting; Spaceship reads it after the managed ones.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/spaceship";
  };
}
