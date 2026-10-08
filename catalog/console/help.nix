let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.console = {
    title = "Console";
    summary = metadata.description;
    tips = [
      {
        label = "Session";
        text = "limanix-session NAME";
      }
      {
        label = "Edit";
        text = "nvim .";
      }
      {
        label = "Key hints";
        text = "In AstroNvim, press Space and wait for the hints.";
      }
      {
        label = "Component";
        text = "lmx help tmux";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/console/README.html";
  };
}
