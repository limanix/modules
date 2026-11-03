let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.pure = {
    title = "Pure";
    summary = metadata.description;
    tips = [
      {
        label = "Colors";
        text = "zstyle ':prompt:pure:path' color cyan in ~/.zshrc changes one color.";
      }
      {
        label = "Right side";
        text = "RPROMPT in ~/.zshrc replaces the lmx words on the right.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/pure";
  };
}
