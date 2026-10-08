let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.lazygit = {
    title = "Lazygit";
    summary = metadata.description;
    commands = [ "lazygit" ];
    tips = [
      {
        label = "Commit";
        text = "Press Space on a file to stage it, then c to commit.";
      }
      {
        label = "Sync";
        text = "Press P to push and p to pull.";
      }
      {
        label = "Keys";
        text = "Press ? for the key bindings.";
      }
      {
        label = "Settings";
        text = "Personal settings go in ~/.config/lazygit/config.yml.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/lazygit/README.html";
  };
}
