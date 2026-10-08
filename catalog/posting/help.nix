let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.posting = {
    title = "Posting";
    summary = metadata.description;
    commands = [ "posting" ];
    tips = [
      {
        label = "Project";
        text = "posting --collection ./requests";
      }
      {
        label = "Send";
        text = "Press Ctrl-J to send the request.";
      }
      {
        label = "Save";
        text = "Press Ctrl-S to save the request to the collection.";
      }
      {
        label = "Keys";
        text = "Press F1 for the key bindings of the focused widget.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/posting/README.html";
  };
}
