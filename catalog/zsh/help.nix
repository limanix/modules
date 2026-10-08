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
      "starship"
      "carapace"
    ];
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
    guide = "https://limanix.dev/categories/nixos/modules/zsh/README.html";
  };
}
