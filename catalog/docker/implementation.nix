version:
{
  pinned,
  pkgs,
  lib,
  config,
  ...
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) pins;
  tools = import ./packages.nix {
    inherit version pinned pkgs;
  };
in
{
  lmx.pins = pins;
  lmx.internal.docker.packages.${version} = tools;

  virtualisation.docker = {
    enable = true;
    package = tools.docker;
  };

  users.users.${config.limanix.user.name}.extraGroups = [ "docker" ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
}
