{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.taskfile.versions);
  versions = map (line: config.lmx.internal.taskfile.packages.${line}.task.version) selected;
in
{
  limanix.help.taskfile = {
    title = "Task ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "task"
      "go-task"
    ]
    ++ map (line: "task-${line}") selected;
    tips = [
      {
        label = "List";
        text = "task --list";
      }
      {
        label = "Run";
        text = "task build";
      }
      {
        label = "Rerun";
        text = "task build --force";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/taskfile/README.html";
  };
}
