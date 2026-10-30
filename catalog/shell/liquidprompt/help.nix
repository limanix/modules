let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.liquidprompt = {
    title = "Liquidprompt";
    summary = metadata.description;
    tips = [
      {
        label = "Settings";
        text = "~/.config/liquidpromptrc replaces /etc/liquidpromptrc: start from a copy.";
      }
      {
        label = "Tag";
        text = "prompt_tag NAME puts a word in front of the prompt.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/liquidprompt";
  };
}
