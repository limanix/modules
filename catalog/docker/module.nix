version:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  imports = [ ../lazydocker/default.nix ];

  virtualisation.docker = {
    enable = true;
    package = tools.docker;
  };

  users.users.${config.limanix.user.name}.extraGroups = [ "docker" ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
}
