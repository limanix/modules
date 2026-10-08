{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.docker.versions);
  versions = map (line: config.lmx.internal.docker.packages.${line}.docker.version) selected;
in
{
  limanix.help.docker = {
    title = "Docker ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [ "docker" ];
    tips = [
      {
        label = "Check";
        text = "docker ps";
      }
      {
        label = "Compose";
        text = "docker compose up -d";
      }
      {
        label = "Publish";
        text = "docker run -p 8080:80 IMAGE";
      }
      {
        label = "Local only";
        text = "docker run -p 127.0.0.1:8080:80 IMAGE";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/docker/README.html";
  };
}
