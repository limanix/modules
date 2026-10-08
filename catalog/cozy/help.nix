let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.cozy = {
    title = "Cozy";
    summary = metadata.description;
    commands = [ "tmux-project" ];
    tips = [
      {
        label = "Project";
        text = "tmux-project DIRECTORY";
      }
      {
        label = "Windows";
        text = "Press Ctrl-B, then n or p to change windows.";
      }
      {
        label = "Component";
        text = "lmx help docker";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/cozy/README.html";
  };
}
