let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.powerlevel10k = {
    title = "Powerlevel10k";
    summary = metadata.description;
    tips = [
      {
        label = "Configure";
        text = "p10k configure writes ~/.p10k.zsh, which replaces the managed style.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/powerlevel10k";
  };
}
