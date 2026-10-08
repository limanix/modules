{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.python.versions);
  versions = map (line: config.lmx.internal.python.packages.${line}.python.version) selected;
in
{
  limanix.help.python = {
    title = "Python ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "python"
      "virtualenv"
      "pyright"
    ]
    ++ map (line: "python-${line}") selected;
    tips = [
      {
        label = "New venv";
        text = "python -m venv .venv && source .venv/bin/activate";
      }
      {
        label = "Install";
        text = "python -m pip install -r requirements.txt";
      }
      {
        label = "Leave";
        text = "deactivate";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/python/README.html";
  };
}
