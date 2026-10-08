let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.tmux = {
    title = "tmux";
    summary = metadata.description;
    commands = [ "tmux" ];
    tips = [
      {
        label = "Session";
        text = "limanix-session NAME";
      }
      {
        label = "Split";
        text = "Press Ctrl-B, then % or \" to split the window.";
      }
      {
        label = "Detach";
        text = "Press Ctrl-B, then d; the session keeps running.";
      }
      {
        label = "Keys";
        text = "Press Ctrl-B, then ? for the key bindings.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/tmux/README.html";
  };
}
