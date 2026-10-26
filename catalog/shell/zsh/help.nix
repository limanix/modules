{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.zsh = {
    title = "Zsh";
    summary = metadata.description;
    commands = [
      "zsh"
      "direnv"
      "atuin"
      "fzf"
      "zoxide"
      "carapace"
    ]
    ++ lib.optional (config.lmx.zsh.prompt == "starship") "starship";
    tips = [
      {
        label = "History";
        text = "Press Ctrl-R to search recorded commands.";
      }
      {
        label = "Complete";
        text = "Press Tab to search completion candidates.";
      }
      {
        label = "Jump";
        text = "z NAME";
      }
      {
        label = "Allow env";
        text = "direnv allow";
      }
    ];
    guide = "https://docs.limanix.dev/modules/zsh";
  };
}
