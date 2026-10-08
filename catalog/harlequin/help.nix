let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.harlequin = {
    title = "Harlequin";
    summary = metadata.description;
    commands = [ "harlequin" ];
    tips = [
      {
        label = "PostgreSQL";
        text = "harlequin --adapter postgres \"postgresql://USER@HOST/DATABASE\"";
      }
      {
        label = "SQLite";
        text = "harlequin --adapter sqlite ./database.sqlite";
      }
      {
        label = "Profile";
        text = "harlequin --config";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/harlequin/README.html";
  };
}
