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
        text = "harlequin --adapter postgres --host \"$XDG_RUNTIME_DIR/postgresql-18\" --dbname postgres";
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
    guide = "https://docs.limanix.dev/modules/harlequin";
  };
}
