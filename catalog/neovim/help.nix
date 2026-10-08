let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.neovim = {
    title = "Neovim";
    summary = metadata.description;
    commands = [
      "nvim"
      "vim"
      "vi"
    ];
    tips = [
      {
        label = "Open";
        text = "nvim notes.md";
      }
      {
        label = "Quit";
        text = "Type :q to quit, or :wq to save and quit.";
      }
      {
        label = "Default";
        text = "Set programs.neovim.defaultEditor = true in a custom module.";
      }
      {
        label = "LSP";
        text = "Select lmx:astronvim for language servers and completion.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/neovim/README.html";
  };
}
