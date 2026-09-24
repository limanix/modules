version:
{
  pkgs,
  lib,
  runtime,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  virtualisation.docker = {
    enable = true;
    package = tools.docker;
  };

  users.users.${runtime.user.name}.extraGroups = [ "docker" ];

  warnings = lib.optional tools.endOfLife "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
}
