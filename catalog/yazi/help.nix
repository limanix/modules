let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.yazi = {
    title = "Yazi";
    summary = metadata.description;
    commands = [
      "yazi"
      "ya"
    ];
    tips = [
      {
        label = "Browse";
        text = "y";
      }
      {
        label = "Quit";
        text = "Press q to move the shell to Yazi's directory, or Q to stay.";
      }
      {
        label = "Keys";
        text = "Press F1 or ~ for the key bindings.";
      }
      {
        label = "Shared";
        text = "Changes to files in shared folders also change them on the Mac.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/yazi/README.html";
  };
}
