{
  name = "docker";
  title = "Docker";
  product = "Docker Engine";
  directory = ./.;
  main = "docker";
  single = true;
  packages = import ./packages.nix;
  extra = { pkgs, ... }: { environment.systemPackages = [ pkgs.lazydocker ]; };
  line =
    { tools, config, ... }:
    {
      virtualisation.docker = {
        enable = true;
        package = tools.docker;
      };

      users.users.${config.limanix.user.name}.extraGroups = [ "docker" ];
    };
  commands = [
    "docker"
    "lazydocker"
  ];
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
  page = "modules/docker";
}
